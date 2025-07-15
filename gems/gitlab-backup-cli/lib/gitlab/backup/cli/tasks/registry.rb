# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Registry < Task
          def self.id = 'registry'

          def enabled = context.registry_enabled?

          def human_name = 'Container Registry Images'

          def destination_path = 'registry.tar.gz'

          attr_reader :registry_bucket

          def set_registry_bucket(registry_bucket)
            @registry_bucket = registry_bucket
          end

          def object_storage?
            !registry_bucket.nil?
          end

          # Registry does not use consolidated object storage config.
          def config
            unless context
              Output.warning("No context passed to derive configuration from.")
              return nil
            end

            {
              object_storage: {
                connection: context.object_storage_connection,
                remote_directory: registry_bucket
              }
            }
          end

          private

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path)
          end

          def storage_path = context.registry_path
        end
      end
    end
  end
end
