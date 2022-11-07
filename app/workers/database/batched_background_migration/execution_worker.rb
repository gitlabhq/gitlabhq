# frozen_string_literal: true

module Database
  module BatchedBackgroundMigration
    class ExecutionWorker # rubocop:disable Scalability/IdempotentWorker
      include Gitlab::Utils::StrongMemoize

      INTERVAL_VARIANCE = 5.seconds.freeze

      def perform(database_name, migration_id)
        self.database_name = database_name

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          migration = find_migration(migration_id)

          break unless migration

          run(migration) if migration.active? && migration.interval_elapsed?(variance: INTERVAL_VARIANCE)
        end
      end

      private

      attr_accessor :database_name

      def base_model
        strong_memoize(:base_model) do
          Gitlab::Database.database_base_models[database_name]
        end
      end

      def find_migration(id)
        Gitlab::Database::BackgroundMigration::BatchedMigration.find_executable(id, connection: base_model.connection)
      end

      def run(migration)
        Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new(connection: base_model.connection)
          .run_migration_job(migration)
      end
    end
  end
end
