# frozen_string_literal: true

module Backup
  module Tasks
    class Repositories < Task
      attr_reader :server_side

      def self.id = 'repositories'

      def initialize(progress:, options:, server_side:)
        @server_side = server_side

        super(progress: progress, options: options)
      end

      def human_name = _('repositories')

      def destination_path = 'repositories'

      def destination_optional = true

      def target
        strategy = Backup::GitalyBackup.new(progress,
          incremental: options.incremental?,
          max_parallelism: options.max_parallelism,
          storage_parallelism: options.max_storage_parallelism,
          server_side: server_side
        )

        ::Backup::Targets::Repositories.new(progress,
          strategy: strategy,
          options: options,
          storages: options.repositories_storages,
          paths: options.repositories_paths,
          skip_paths: options.skip_repositories_paths
        )
      end
    end
  end
end
