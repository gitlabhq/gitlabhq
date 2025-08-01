# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            class BmDesiredConfigYamlParser # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              # @param [Hash] context
              # @return [Hash]
              def self.parse(context)
                context => {
                  desired_config_yaml: desired_config_yaml
                }

                desired_config_array = YAML.load_stream(desired_config_yaml).map(&:deep_symbolize_keys)

                context.merge({
                  desired_config_array: desired_config_array
                })
              end
            end
          end
        end
      end
    end
  end
end
