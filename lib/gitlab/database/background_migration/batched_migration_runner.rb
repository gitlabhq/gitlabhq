# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationRunner
        FailedToFinalize = Class.new(RuntimeError)

        def self.finalize(job_class_name, table_name, column_name, job_arguments, connection:)
          new(connection: connection).finalize(job_class_name, table_name, column_name, job_arguments)
        end

        def initialize(connection:, migration_wrapper: BatchedMigrationWrapper.new(connection: connection))
          @connection = connection
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

            adjust_migration(active_migration)

            active_migration.failure! if next_batched_job.failed? && active_migration.should_stop?
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

          run_migration_while(migration, :active)
        end

        # Finalize migration for given configuration.
        #
        # If the migration is already finished, do nothing. Otherwise change its status to `finalizing`
        # in order to prevent it being picked up by the background worker. Perform all pending jobs,
        # then keep running until migration is finished.
        def finalize(job_class_name, table_name, column_name, job_arguments)
          migration = BatchedMigration.find_for_configuration(
            Gitlab::Database.gitlab_schemas_for_connection(connection),
            job_class_name, table_name, column_name, job_arguments
          )

          configuration = {
            job_class_name: job_class_name,
            table_name: table_name,
            column_name: column_name,
            job_arguments: job_arguments
          }

          if migration.nil?
            Gitlab::AppLogger.warn "Could not find batched background migration for the given configuration: #{configuration}"
          elsif migration.finished?
            Gitlab::AppLogger.warn "Batched background migration for the given configuration is already finished: #{configuration}"
          else
            migration.reset_attempts_of_blocked_jobs!

            migration.finalize!
            migration.batched_jobs.with_status(:pending).each { |job| migration_wrapper.perform(job) }

            run_migration_while(migration, :finalizing)

            error_message = "Batched migration #{migration.job_class_name} could not be completed and a manual action is required."\
                            "Check the admin panel at (`/admin/background_migrations`) for more details."

            raise FailedToFinalize, error_message unless migration.finished?
          end
        end

        private

        attr_reader :connection, :migration_wrapper

        def find_or_create_next_batched_job(active_migration)
          next_batch_min, next_batch_max = find_next_batch_range(active_migration)

          return active_migration.batched_jobs.retriable.first if next_batch_min.nil? || next_batch_max.nil?

          active_migration.create_batched_job!(next_batch_min, next_batch_max)
        end

        def find_next_batch_range(active_migration)
          batching_strategy = active_migration.batch_class.new(connection: connection)
          batch_min_value = active_migration.next_min_value

          next_batch_bounds = batching_strategy.next_batch(
            active_migration.table_name,
            active_migration.column_name,
            batch_min_value: batch_min_value,
            batch_size: active_migration.batch_size,
            job_arguments: active_migration.job_arguments,
            job_class: active_migration.job_class)

          return if next_batch_bounds.nil?

          clamped_batch_range(active_migration, next_batch_bounds)
        end

        def clamped_batch_range(active_migration, next_bounds)
          next_min, next_max = next_bounds

          if active_migration.cursor?
            return if (next_min <=> active_migration.max_cursor) > 0

            next_max = active_migration.max_cursor if (next_max <=> active_migration.max_cursor) > 0
          else
            return if next_min > active_migration.max_value

            next_max = next_max.clamp(next_min, active_migration.max_value)
          end

          [next_min, next_max]
        end

        def finish_active_migration(active_migration)
          return if active_migration.batched_jobs.active.exists?

          if active_migration.batched_jobs.with_status(:failed).exists?
            active_migration.failure!
          else
            active_migration.finish!
          end
        end

        def run_migration_while(migration, status)
          while migration.status_name == status
            run_migration_job(migration)
            migration.reload_last_job
          end
        end

        def adjust_migration(active_migration)
          signals = Gitlab::Database::HealthStatus.evaluate(active_migration.health_context)

          if signals.any?(&:stop?)
            active_migration.hold!
          else
            active_migration.optimize!
          end
        end
      end
    end
  end
end
