# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationRunner
        def initialize(migration_wrapper = BatchedMigrationWrapper.new)
          @migration_wrapper = migration_wrapper
        end

        def run_migration_job(active_migration)
          if next_batched_job = create_next_batched_job!(active_migration)
            migration_wrapper.perform(next_batched_job)
          else
            finish_active_migration(active_migration)
          end
        end

        def run_entire_migration(migration)
          while migration.active?
            run_migration_job(migration)

            migration.reload_last_job
          end
        end

        private

        attr_reader :migration_wrapper

        def create_next_batched_job!(active_migration)
          next_batch_range = find_next_batch_range(active_migration)

          return if next_batch_range.nil?

          active_migration.create_batched_job!(next_batch_range.min, next_batch_range.max)
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
          active_migration.finished!
        end
      end
    end
  end
end
