#!/bin/sh
echo "$(date -Iseconds): ----------------------------------------"
echo "$(date -Iseconds): Starting sshd in background if it is found..."
sshd_path=$(which sshd)
if [ -x "${sshd_path}" ]; then
  echo "$(date -Iseconds): Starting ${sshd_path} in background on port ${GL_SSH_PORT} with output written to ${GL_WORKSPACE_LOGS_DIR}/start-sshd.log"
  "${sshd_path}" -D -p "${GL_SSH_PORT}" >> "${GL_WORKSPACE_LOGS_DIR}/start-sshd.log" 2>&1 &
  echo "$(date -Iseconds): Finished starting sshd in background if it is found."
else
  echo "$(date -Iseconds): 'sshd' not found in path. Not starting SSH server." >&2
  echo "$(date -Iseconds): Failed to start sshd, no sshd executable found"
fi
echo "$(date -Iseconds): ----------------------------------------"
