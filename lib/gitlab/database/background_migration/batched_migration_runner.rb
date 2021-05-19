# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationRunner
        def initialize(migration_wrapper = BatchedMigrationWrapper.new)
          @migration_wrapper = migration_wrapper
        end

        # Runs the next batched_job for a batched_background_migration.
        #
        # The batch bounds of the next job are calculated at runtime, based on the migration
        # configuration and the bounds of the most recently created batched_job. Updating the
        # migration configuration will cause future jobs to use the updated batch sizes.
        #
        # The job instance will automatically receive a set of arguments based on the migration
        # configuration. For more details, see the BatchedMigrationWrapper class.
        #
        # Note that this method is primarily intended to called by a scheduled worker.
        def run_migration_job(active_migration)
          if next_batched_job = find_or_create_next_batched_job(active_migration)
            migration_wrapper.perform(next_batched_job)

            active_migration.optimize!
          else
            finish_active_migration(active_migration)
          end
        end

        # Runs all remaining batched_jobs for a batched_background_migration.
        #
        # This method is intended to be used in a test/dev environment to execute the background
        # migration inline. It should NOT be used in a real environment for any non-trivial migrations.
        def run_entire_migration(migration)
          unless Rails.env.development? || Rails.env.test?
            raise 'this method is not intended for use in real environments'
          end

          while migration.active?
            run_migration_job(migration)

            migration.reload_last_job
          end
        end

        private

        attr_reader :migration_wrapper

        def find_or_create_next_batched_job(active_migration)
          if next_batch_range = find_next_batch_range(active_migration)
            active_migration.create_batched_job!(next_batch_range.min, next_batch_range.max)
          else
            active_migration.batched_jobs.retriable.first
          end
        end

        def find_next_batch_range(active_migration)
          batching_strategy = active_migration.batch_class.new
          batch_min_value = active_migration.next_min_value

          next_batch_bounds = batching_strategy.next_batch(
            active_migration.table_name,
            active_migration.column_name,
            batch_min_value: batch_min_value,
            batch_size: active_migration.batch_size)

          return if next_batch_bounds.nil?

          clamped_batch_range(active_migration, next_batch_bounds)
        end

        def clamped_batch_range(active_migration, next_bounds)
          min_value, max_value = next_bounds

          return if min_value > active_migration.max_value

          max_value = max_value.clamp(min_value, active_migration.max_value)

          (min_value..max_value)
        end

        def finish_active_migration(active_migration)
          return if active_migration.batched_jobs.active.exists?

          if active_migration.batched_jobs.failed.exists?
            active_migration.failed!
          else
            active_migration.finished!
          end
        end
      end
    end
  end
end
