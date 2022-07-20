# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class TestBatchedBackgroundRunner < BaseBackgroundRunner
        attr_reader :connection

        def initialize(result_dir:, connection:)
          super(result_dir: result_dir)
          @connection = connection
        end

        def jobs_by_migration_name
          Gitlab::Database::BackgroundMigration::BatchedMigration
            .executable
            .created_after(3.hours.ago) # Simple way to exclude migrations already running before migration testing
            .to_h do |migration|
            batching_strategy = migration.batch_class.new(connection: connection)

            all_migration_jobs = []

            min_value = migration.next_min_value

            while (next_bounds = batching_strategy.next_batch(
              migration.table_name,
              migration.column_name,
              batch_min_value: min_value,
              batch_size: migration.batch_size,
              job_arguments: migration.job_arguments
            ))

              batch_min, batch_max = next_bounds

              all_migration_jobs << migration.create_batched_job!(batch_min, batch_max)
              min_value = batch_max + 1
            end

            [migration.job_class_name, all_migration_jobs]
          end
        end

        def run_job(job)
          Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new(connection: connection).perform(job)
        end
      end
    end
  end
end
