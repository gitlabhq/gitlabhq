#!/bin/sh

mkdir -p "${GL_WORKSPACE_LOGS_DIR}"
ln -sf "${GL_WORKSPACE_LOGS_DIR}" /tmp

{
    echo "$(date -Iseconds): ----------------------------------------"
    echo "$(date -Iseconds): Running poststart commands for workspace..."

    echo "$(date -Iseconds): ----------------------------------------"
    echo "$(date -Iseconds): Running internal blocking poststart commands script..."
} >> "${GL_WORKSPACE_LOGS_DIR}/poststart-stdout.log"

"%<run_internal_blocking_poststart_commands_script_file_path>s" 1>>"${GL_WORKSPACE_LOGS_DIR}/poststart-stdout.log" 2>>"${GL_WORKSPACE_LOGS_DIR}/poststart-stderr.log"

{
    echo "$(date -Iseconds): ----------------------------------------"
    echo "$(date -Iseconds): Running non-blocking poststart commands script..."
} >> "${GL_WORKSPACE_LOGS_DIR}/poststart-stdout.log"

"%<run_non_blocking_poststart_commands_script_file_path>s" 1>>"${GL_WORKSPACE_LOGS_DIR}/poststart-stdout.log" 2>>"${GL_WORKSPACE_LOGS_DIR}/poststart-stderr.log" &
