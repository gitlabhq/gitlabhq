#!/bin/sh

echo "$(date -Iseconds): ----------------------------------------"
echo "$(date -Iseconds): Spawning background process to unshallow repo if necessary..."

if [ ! -f "%<project_cloning_successful_file>s" ]; then
  echo "$(date -Iseconds): Project cloning previously failed. Unshallow skipped"
  echo "$(date -Iseconds): ----------------------------------------"
  exit 0
fi

# shellcheck disable=SC2164 # We assume that 'clone_dir' must exist if 'project_cloning_successful_file' exists
cd "%<clone_dir>s"

if [ "$(git rev-parse --is-shallow-repository)" != "true" ]; then
  echo "$(date -Iseconds): Repository is not shallow, skipping unshallow"
  echo "$(date -Iseconds): ----------------------------------------"
  exit 0
fi

echo "$(date -Iseconds): Repository is shallow, proceeding with unshallow"
UNSHALLOW_LOG_FILE="${GL_WORKSPACE_LOGS_DIR}/clone-unshallow.log"

echo "$(date -Iseconds): Starting unshallow in background, with output written to ${UNSHALLOW_LOG_FILE}"
{
  echo "$(date -Iseconds): ----------------------------------------"
  echo "$(date -Iseconds): Starting unshallow in background"
  if git fetch --unshallow --progress 2>&1; then
    echo "$(date -Iseconds): Unshallow completed successfully"
  else
    echo "$(date -Iseconds): Unshallow failed with exit code $?"
  fi
  echo "$(date -Iseconds): ----------------------------------------"
} >> "${UNSHALLOW_LOG_FILE}" &

echo "$(date -Iseconds): Finished spawning background process to unshallow repo."
echo "$(date -Iseconds): ----------------------------------------"
exit 0
