# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            class BmScriptsVolumeInserter # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              include BmCreateConstants

              # @param [String] configmap_name
              # @param [Array<Hash>] containers
              # @param [Array<Hash>] volumes
              # @return [void]
              def self.insert(configmap_name:, containers:, volumes:)
                volume =
                  {
                    name: WORKSPACE_SCRIPTS_VOLUME_NAME,
                    projected: {
                      defaultMode: WORKSPACE_SCRIPTS_VOLUME_DEFAULT_MODE,
                      sources: [
                        {
                          configMap: {
                            name: configmap_name
                          }
                        }
                      ]
                    }
                  }
                volume_mount =
                  {
                    name: WORKSPACE_SCRIPTS_VOLUME_NAME,
                    mountPath: WORKSPACE_SCRIPTS_VOLUME_PATH
                  }

                volumes << volume
                containers.each do |container|
                  container.fetch(:volumeMounts) << volume_mount
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
