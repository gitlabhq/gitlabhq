#!/bin/sh
echo "$(date -Iseconds): ----------------------------------------"
echo "$(date -Iseconds): Sleeping until workspace is running..."
time_to_sleep=5
status_file="%<workspace_reconciled_actual_state_file_path>s"
while [ "$(cat ${status_file})" != "Running" ]; do
  echo "$(date -Iseconds): Workspace state is '$(cat ${status_file})' from status file '${status_file}'. Blocking remaining postStart events execution for ${time_to_sleep} seconds until state is 'Running'..."
  sleep ${time_to_sleep}
done
echo "$(date -Iseconds): Workspace state is now 'Running', continuing postStart hook execution."
echo "$(date -Iseconds): Finished sleeping until workspace is running."
echo "$(date -Iseconds): ----------------------------------------"
