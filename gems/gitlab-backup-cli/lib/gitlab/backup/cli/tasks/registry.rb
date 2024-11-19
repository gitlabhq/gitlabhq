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

          attr_reader :registry_bucket

          def set_registry_bucket(registry_bucket)
            @registry_bucket = registry_bucket
          end

          def object_storage?
            !registry_bucket.nil?
          end

          # Registry does not use consolidated object storage config.
          def config
            settings = {
              object_store: {
                connection: context.gitlab_config('object_store').connection.to_hash,
                remote_directory: registry_bucket
              }
            }
            GitlabSettings::Options.build(settings)
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
