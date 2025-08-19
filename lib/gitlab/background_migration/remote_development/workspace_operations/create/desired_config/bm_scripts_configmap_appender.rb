# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            class BmScriptsConfigmapAppender # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              include BmCreateConstants
              include BmWorkspaceOperationsConstants

              # @param [Array] desired_config_array
              # @param [String] name
              # @param [String] namespace
              # @param [Hash] labels
              # @param [Hash] annotations
              # @param [Array<Hash>] devfile_commands
              # @param [Hash] devfile_events
              # @return [void]
              def self.append(
                desired_config_array:,
                name:,
                namespace:,
                labels:,
                annotations:,
                devfile_commands:,
                devfile_events:
              )
                configmap_data = {}

                configmap =
                  {
                    kind: "ConfigMap",
                    apiVersion: "v1",
                    metadata: {
                      name: name,
                      namespace: namespace,
                      labels: labels,
                      annotations: annotations
                    },
                    data: configmap_data
                  }

                add_devfile_command_scripts_to_configmap_data(
                  configmap_data: configmap_data,
                  devfile_commands: devfile_commands,
                  devfile_events: devfile_events
                )

                add_run_poststart_commands_script_to_configmap_data(
                  configmap_data: configmap_data,
                  devfile_commands: devfile_commands,
                  devfile_events: devfile_events
                )

                # noinspection RubyMismatchedArgumentType - RubyMine is misinterpreting types for Hash values
                configmap[:data] = Gitlab::Utils.deep_sort_hashes(configmap_data).to_h

                desired_config_array.append(configmap)

                nil
              end

              # @param [Hash] configmap_data
              # @param [Array<Hash>] devfile_commands
              # @param [Hash] devfile_events
              # @return [void]
              def self.add_devfile_command_scripts_to_configmap_data(
                configmap_data:,
                devfile_commands:,
                devfile_events:
              )
                devfile_events => { postStart: Array => poststart_command_ids }

                poststart_command_ids.each do |poststart_command_id|
                  command = devfile_commands.find { |command| command.fetch(:id) == poststart_command_id }
                  command => {
                    exec: {
                      commandLine: String => command_line
                    }
                  }

                  configmap_data[poststart_command_id.to_sym] = command_line
                end

                nil
              end

              # @param [Hash] configmap_data
              # @param [Array<Hash>] devfile_commands
              # @param [Hash] devfile_events
              # @return [void]
              def self.add_run_poststart_commands_script_to_configmap_data(
                configmap_data:,
                devfile_commands:,
                devfile_events:
              )
                devfile_events => { postStart: Array => poststart_command_ids }

                internal_blocking_command_label_present = devfile_commands.find do |command|
                  command.dig(:exec, :label) == INTERNAL_BLOCKING_COMMAND_LABEL
                end

                unless internal_blocking_command_label_present
                  configmap_data[LEGACY_RUN_POSTSTART_COMMANDS_SCRIPT_NAME.to_sym] =
                    <<~SH.chomp
                      #!/bin/sh
                      #{get_poststart_command_script_content(poststart_command_ids: poststart_command_ids)}
                    SH
                  return
                end

                # Segregate internal commands and user provided commands.
                # Before any non-blocking post start command is executed, we wait for the workspace to be marked ready.
                internal_blocking_poststart_command_ids, non_blocking_poststart_command_ids =
                  poststart_command_ids.partition do |id|
                    command = devfile_commands.find { |cmd| cmd[:id] == id }
                    command && command.dig(:exec, :label) == INTERNAL_BLOCKING_COMMAND_LABEL
                  end

                configmap_data[RUN_INTERNAL_BLOCKING_POSTSTART_COMMANDS_SCRIPT_NAME.to_sym] =
                  <<~SH.chomp
                    #!/bin/sh
                    #{get_poststart_command_script_content(poststart_command_ids: internal_blocking_poststart_command_ids)}
                  SH

                configmap_data[RUN_NON_BLOCKING_POSTSTART_COMMANDS_SCRIPT_NAME.to_sym] =
                  <<~SH.chomp
                    #!/bin/sh
                    #{get_poststart_command_script_content(poststart_command_ids: non_blocking_poststart_command_ids)}
                  SH

                nil
              end

              # @param [Array] poststart_command_ids
              # @return [String]
              def self.get_poststart_command_script_content(poststart_command_ids:)
                poststart_command_ids.map do |poststart_command_id|
                  # NOTE: We force all the poststart scripts to exit successfully with `|| true`, to
                  #       prevent the Kubernetes poststart hook from failing, and thus prevent the
                  #       container from exiting. Then users can view logs to debug failures.
                  #       See https://github.com/eclipse-che/che/issues/23404#issuecomment-2787779571
                  #       for more context.
                  <<~SH
                    echo "$(date -Iseconds): ----------------------------------------"
                    echo "$(date -Iseconds): Running #{WORKSPACE_SCRIPTS_VOLUME_PATH}/#{poststart_command_id}..."
                    #{WORKSPACE_SCRIPTS_VOLUME_PATH}/#{poststart_command_id} || true
                    echo "$(date -Iseconds): Finished running #{WORKSPACE_SCRIPTS_VOLUME_PATH}/#{poststart_command_id}."
                  SH
                end.join
              end

              private_class_method :add_devfile_command_scripts_to_configmap_data,
                :add_run_poststart_commands_script_to_configmap_data, :get_poststart_command_script_content
            end
          end
        end
      end
    end
  end
end
