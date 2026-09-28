#!/bin/bash
set -e

LAVALINK_PORT="${SERVER_PORT:-2333}"

if [ -z "${LAVALINK_SERVER_PASSWORD}" ]; then
  echo "[start.sh] LAVALINK_SERVER_PASSWORD is empty. Refusing to start."
  echo "[start.sh] An empty password does NOT mean 'no auth' the way you'd expect -"
  echo "[start.sh] Lavalink treats a request with a blank Authorization header as"
  echo "[start.sh] authenticated, so this node would be silently open to anyone."
  echo "[start.sh] Set LAVALINK_SERVER_PASSWORD in the environment and redeploy."
  exit 1
fi

echo "[start.sh] Starting Lavalink on internal port ${LAVALINK_PORT}..."
java ${_JAVA_OPTIONS:--Xmx512M} -jar /opt/Lavalink/Lavalink.jar &
LAVALINK_PID=$!

echo "[start.sh] Waiting for Lavalink to become healthy..."
until curl -sf -o /dev/null "http://127.0.0.1:${LAVALINK_PORT}/version"; do
  if ! kill -0 "$LAVALINK_PID" 2>/dev/null; then
    echo "[start.sh] Lavalink process died before becoming healthy. Exiting."
    exit 1
  fi
  sleep 1
done
echo "[start.sh] Lavalink is up."

echo "[start.sh] Starting dashboard + proxy on public port ${PORT:-3000}..."
cd /opt/proxy
node server.js &
PROXY_PID=$!

# Kalau salah satu proses mati, matikan container supaya Render restart otomatis
wait -n "$LAVALINK_PID" "$PROXY_PID"
exit $?
