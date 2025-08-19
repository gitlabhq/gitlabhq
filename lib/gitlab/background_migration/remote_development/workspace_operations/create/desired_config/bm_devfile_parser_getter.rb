# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            class BmDevfileParserGetter # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              include BmWorkspaceOperationsConstants

              # @param [Hash] context
              # @return [Hash]
              def self.get(context) # rubocop:disable Metrics/MethodLength -- This method is complex but we don't need to break it up.
                context => {
                  logger: logger,
                  processed_devfile_yaml: processed_devfile_yaml,
                  workspace_inventory_annotations_for_partial_reconciliation:
                  workspace_inventory_annotations_for_partial_reconciliation,
                  domain_template: domain_template,
                  labels: labels,
                  workspace_name: workspace_name,
                  workspace_namespace: workspace_namespace,
                  replicas: replicas
                }

                begin
                  context.merge(
                    desired_config_yaml: Devfile::Parser.get_all(
                      processed_devfile_yaml,
                      workspace_name,
                      workspace_namespace,
                      YAML.dump(labels.deep_stringify_keys),
                      YAML.dump(workspace_inventory_annotations_for_partial_reconciliation.deep_stringify_keys),
                      replicas,
                      domain_template,
                      'none'
                    )
                  )
                rescue Devfile::CliError => e
                  error_message = <<~MSG.squish
                    #{e.class}: A non zero return code was observed when invoking the devfile CLI
                    executable from the devfile gem.
                  MSG
                  logger.warn(
                    message: error_message,
                    error_type: 'create_devfile_parser_error',
                    workspace_name: workspace_name,
                    workspace_namespace: workspace_namespace,
                    devfile_parser_error: e.message
                  )
                  raise e
                rescue StandardError => e
                  error_message = <<~MSG.squish
                    #{e.class}: An unrecoverable error occurred when invoking the devfile gem,
                    this may hint that a gem with a wrong architecture is being used.
                  MSG
                  logger.warn(
                    message: error_message,
                    error_type: 'create_devfile_parser_error',
                    workspace_name: workspace_name,
                    workspace_namespace: workspace_namespace,
                    devfile_parser_error: e.message
                  )
                  raise e
                end
              end
            end
          end
        end
      end
    end
  end
end
