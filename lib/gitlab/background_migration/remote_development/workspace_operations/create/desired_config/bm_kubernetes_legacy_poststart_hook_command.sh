#!/bin/sh

mkdir -p "${GL_WORKSPACE_LOGS_DIR}"
ln -sf "${GL_WORKSPACE_LOGS_DIR}" /tmp
"%<run_internal_blocking_poststart_commands_script_file_path>s" 1>>"${GL_WORKSPACE_LOGS_DIR}/poststart-stdout.log" 2>>"${GL_WORKSPACE_LOGS_DIR}/poststart-stderr.log"
