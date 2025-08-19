# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          # NOTE: Constants are scoped to the use-case namespace in which they are used in production
          #       code (but they may still be referenced by specs or fixtures or factories).
          #       For example, this RemoteDevelopment::BMWorkspaceOperations::Create::BmCreateConstants
          #       file contains constants which are only used by classes within that namespace.
          #
          #       See documentation at ../../README.md#constant-declarations for more information.
          module BmCreateConstants
            include BmWorkspaceOperationsConstants

            # Please keep alphabetized
            GIT_CREDENTIAL_STORE_SCRIPT_FILE_NAME = "gl_git_credential_store.sh"
            GIT_CREDENTIAL_STORE_SCRIPT_FILE_PATH =
              "#{VARIABLES_VOLUME_PATH}/#{GIT_CREDENTIAL_STORE_SCRIPT_FILE_NAME}".freeze
            LEGACY_RUN_POSTSTART_COMMANDS_SCRIPT_NAME = "gl-run-poststart-commands.sh"
            NAMESPACE_PREFIX = "gl-rd-ns"
            PROJECT_CLONING_SUCCESSFUL_FILE_NAME = ".gl_project_cloning_successful"
            CLONE_DEPTH_OPTION = "--depth 10"
            RUN_AS_USER = 5001
            RUN_INTERNAL_BLOCKING_POSTSTART_COMMANDS_SCRIPT_NAME = "gl-run-internal-blocking-poststart-commands.sh"
            RUN_NON_BLOCKING_POSTSTART_COMMANDS_SCRIPT_NAME = "gl-run-non-blocking-poststart-commands.sh"
            TOKEN_FILE_NAME = "gl_token"
            TOKEN_FILE_PATH = "#{VARIABLES_VOLUME_PATH}/#{TOKEN_FILE_NAME}".freeze
            TOOLS_DIR_NAME = ".gl-tools"
            TOOLS_DIR_ENV_VAR = "GL_TOOLS_DIR"
            TOOLS_INJECTOR_COMPONENT_NAME = "gl-tools-injector"
            WORKSPACE_DATA_VOLUME_NAME = "gl-workspace-data"
            WORKSPACE_EDITOR_PORT = 60001
            WORKSPACE_SCRIPTS_VOLUME_DEFAULT_MODE = 0o555
            WORKSPACE_SCRIPTS_VOLUME_NAME = "gl-workspace-scripts"
            WORKSPACE_SCRIPTS_VOLUME_PATH = "/workspace-scripts"
            WORKSPACE_SSH_PORT = 60022
          end
        end
      end
    end
  end
end
