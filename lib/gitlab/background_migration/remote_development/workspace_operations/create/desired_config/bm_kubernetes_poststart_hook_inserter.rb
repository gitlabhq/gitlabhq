# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            # NOTE: This class has "Kubernetes" prepended to "Poststart" in the name to make it explicit that it
            #       deals with Kubernetes postStart hooks in the Kubernetes Deployment resource, and that
            #       it is NOT dealing with the postStart events which are found in devfiles.
            class BmKubernetesPoststartHookInserter # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              include BmFiles
              include BmCreateConstants

              # @param [Array] containers
              # @param [Array<Hash>] devfile_commands
              # @param [Hash] devfile_events
              # @return [void]
              def self.insert(containers:, devfile_commands:, devfile_events:) # rubocop:disable Metrics/MethodLength -- copied from ee/lib/remote_development
                internal_blocking_command_label_present = devfile_commands.any? do |command|
                  command.dig(:exec, :label) == INTERNAL_BLOCKING_COMMAND_LABEL
                end

                devfile_events => { postStart: Array => poststart_command_ids }

                containers_with_devfile_poststart_commands =
                  poststart_command_ids.each_with_object([]) do |poststart_command_id, accumulator|
                    command = devfile_commands.find { |command| command.fetch(:id) == poststart_command_id }
                    command => {
                      exec: {
                        component: String => container_name
                      }
                    }
                    accumulator << container_name
                  end.uniq

                containers.each do |container| # rubocop:disable Metrics/BlockLength -- need it big
                  container_name = container.fetch(:name)

                  next unless containers_with_devfile_poststart_commands.include?(container_name)

                  if internal_blocking_command_label_present
                    kubernetes_poststart_hook_script =
                      format(
                        KUBERNETES_POSTSTART_HOOK_COMMAND,
                        run_internal_blocking_poststart_commands_script_file_path:
                          "#{WORKSPACE_SCRIPTS_VOLUME_PATH}/#{RUN_INTERNAL_BLOCKING_POSTSTART_COMMANDS_SCRIPT_NAME}",
                        run_non_blocking_poststart_commands_script_file_path:
                          "#{WORKSPACE_SCRIPTS_VOLUME_PATH}/#{RUN_NON_BLOCKING_POSTSTART_COMMANDS_SCRIPT_NAME}"
                      )
                  else
                    kubernetes_poststart_hook_script =
                      format(
                        KUBERNETES_LEGACY_POSTSTART_HOOK_COMMAND,
                        run_internal_blocking_poststart_commands_script_file_path:
                          "#{WORKSPACE_SCRIPTS_VOLUME_PATH}/#{LEGACY_RUN_POSTSTART_COMMANDS_SCRIPT_NAME}"
                      )
                  end

                  container[:lifecycle] = {
                    postStart: {
                      exec: {
                        command: ["/bin/sh", "-c", kubernetes_poststart_hook_script]
                      }
                    }
                  }
                end

                nil
              end
            end
          end
        end
      end
    end
  end
end
