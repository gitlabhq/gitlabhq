# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationWrapper
        # Wraps the execution of a batched_background_migration.
        #
        # Updates the job's tracking records with the status of the migration
        # when starting and finishing execution, and optionally saves batch_metrics
        # the migration provides, if any are given.
        #
        # The job's batch_metrics are serialized to JSON for storage.
        def perform(batch_tracking_record)
          start_tracking_execution(batch_tracking_record)

          execute_batch(batch_tracking_record)

          batch_tracking_record.status = :succeeded
        rescue => e
          batch_tracking_record.status = :failed

          raise e
        ensure
          finish_tracking_execution(batch_tracking_record)
        end

        private

        def start_tracking_execution(tracking_record)
          tracking_record.update!(attempts: tracking_record.attempts + 1, status: :running, started_at: Time.current)
        end

        def execute_batch(tracking_record)
          job_instance = tracking_record.migration_job_class.new

          job_instance.perform(
            tracking_record.min_value,
            tracking_record.max_value,
            tracking_record.migration_table_name,
            tracking_record.migration_column_name,
            tracking_record.sub_batch_size,
            *tracking_record.migration_job_arguments)

          if job_instance.respond_to?(:batch_metrics)
            tracking_record.metrics = job_instance.batch_metrics
          end
        end

        def finish_tracking_execution(tracking_record)
          tracking_record.finished_at = Time.current
          tracking_record.save!
        end
      end
    end
  end
end
