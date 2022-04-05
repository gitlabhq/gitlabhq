# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationWrapper
        def initialize(connection:, metrics: PrometheusMetrics.new)
          @connection = connection
          @metrics = metrics
        end

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

          batch_tracking_record.succeed!
        rescue Exception => error # rubocop:disable Lint/RescueException
          batch_tracking_record.failure!(error: error)

          raise
        ensure
          metrics.track(batch_tracking_record)
        end

        private

        attr_reader :connection, :metrics

        def start_tracking_execution(tracking_record)
          tracking_record.run!
        end

        def execute_batch(tracking_record)
          job_instance = migration_instance_for(tracking_record.migration_job_class)

          job_instance.perform(
            tracking_record.min_value,
            tracking_record.max_value,
            tracking_record.migration_table_name,
            tracking_record.migration_column_name,
            tracking_record.sub_batch_size,
            tracking_record.pause_ms,
            *tracking_record.migration_job_arguments)

          if job_instance.respond_to?(:batch_metrics)
            tracking_record.metrics = job_instance.batch_metrics
          end
        end

        def migration_instance_for(job_class)
          if job_class < Gitlab::BackgroundMigration::BaseJob
            job_class.new(connection: connection)
          else
            job_class.new
          end
        end
      end
    end
  end
end
