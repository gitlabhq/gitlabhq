# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Repositories < Task
          def self.id = 'repositories'

          def human_name = _('repositories')

          def destination_path = 'repositories'

          def destination_optional = true

          private

          def target
            # TODO: migrate to the new codebase and rewrite portions to format output in a readable way
            ::Backup::Targets::Repositories.new($stdout,
              strategy: gitaly_strategy,
              options: options,
              storages: options.repositories_storages,
              paths: options.repositories_paths,
              skip_paths: options.skip_repositories_paths
            )
          end

          def gitaly_strategy
            # TODO: migrate to the new codebase and rewrite portions to format output in a readable way
            ::Backup::GitalyBackup.new($stdout,
              incremental: options.incremental?,
              max_parallelism: options.max_parallelism,
              storage_parallelism: options.max_storage_parallelism,
              server_side: false
            )
          end
        end
      end
    end
  end
end
