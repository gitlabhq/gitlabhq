# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            class BmMain # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              # @param [Hash] parent_context
              # @return [Hash]
              def self.main(parent_context) # rubocop:disable Metrics/MethodLength -- this is a won't fix
                parent_context => {
                  params: params,
                  workspace: workspace,
                  logger: logger
                }

                context = {
                  workspace_id: workspace.id,
                  workspace_name: workspace.name,
                  workspace_namespace: workspace.namespace,
                  workspace_desired_state_is_running: workspace.desired_state_running?,
                  workspaces_agent_id: params[:agent].id,
                  workspaces_agent_config: workspace.workspaces_agent_config,
                  processed_devfile_yaml: workspace.processed_devfile,
                  logger: logger,
                  desired_config_array: []
                }

                initial_result = Gitlab::Fp::Result.ok(context)

                result =
                  initial_result
                    .map(BmConfigValuesExtractor.method(:extract))
                    .map(BmDevfileParserGetter.method(:get))
                    .map(BmDesiredConfigYamlParser.method(:parse))
                    .map(BmDevfileResourceModifier.method(:modify))
                    .map(BmDevfileResourceAppender.method(:append))
                    .map(
                      ->(context) do
                        context.merge(
                          desired_config:
                            RemoteDevelopment::WorkspaceOperations::BmDesiredConfig.new(
                              desired_config_array: context.fetch(:desired_config_array)
                            )
                        )
                      end
                    )

                parent_context[:desired_config] = result.unwrap.fetch(:desired_config)

                parent_context
              end
            end
          end
        end
      end
    end
  end
end
