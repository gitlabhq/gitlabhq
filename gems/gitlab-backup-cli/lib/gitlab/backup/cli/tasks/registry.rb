# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Registry < Task
          def self.id = 'registry'

          def enabled = Gitlab.config.registry.enabled

          def human_name = _('container registry images')

          def destination_path = 'registry.tar.gz'

          def object_storage?
            !options.container_registry_bucket.nil?
          end

          # Registry does not use consolidated object storage config.
          def config
            settings = {
              object_store: {
                connection: context.config('object_store').connection.to_hash,
                remote_directory: options.container_registry_bucket
              }
            }
            GitlabSettings::Options.build(settings)
          end

          private

          def target
            check_object_storage(::Backup::Targets::Files.new(nil, storage_path, options: options))
          end

          def storage_path = context.registry_path
        end
      end
    end
  end
end
