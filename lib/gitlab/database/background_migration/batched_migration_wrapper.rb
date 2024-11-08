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
        # @info The job's batch_metrics are serialized to JSON for storage.
        #
        # @info Track exceptions that could happen when processing sub-batches
        #       through +Gitlab::BackgroundMigration::SubBatchTimeoutException+
        def perform(batch_tracking_record)
          start_tracking_execution(batch_tracking_record)

          execute_batch(batch_tracking_record)

          batch_tracking_record.succeed!
        rescue SubBatchTimeoutError => exception
          caused_by = exception.caused_by
          batch_tracking_record.failure!(error: caused_by, from_sub_batch: true)

          raise caused_by
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
          job_instance = execute_job(tracking_record)

          if job_instance.respond_to?(:batch_metrics)
            tracking_record.metrics = job_instance.batch_metrics
          end
        end

        def execute_job(tracking_record)
          job_class = tracking_record.migration_job_class

          ApplicationContext.push(feature_category: fetch_feature_category(job_class))

          if job_class < Gitlab::BackgroundMigration::BatchedMigrationJob
            execute_batched_migration_job(job_class, tracking_record)
          else
            execute_legacy_job(job_class, tracking_record)
          end
        end

        def execute_batched_migration_job(job_class, tracking_record)
          job_instance = job_class.new(
            **tracking_record.job_attributes.merge({
              connection: connection,
              sub_batch_exception: ::Gitlab::Database::BackgroundMigration::SubBatchTimeoutError
            })
          )

          job_instance.perform

          job_instance
        end

        def execute_legacy_job(job_class, tracking_record)
          job_instance = job_class.new

          job_instance.perform(
            tracking_record.min_value,
            tracking_record.max_value,
            tracking_record.migration_table_name,
            tracking_record.migration_column_name,
            tracking_record.sub_batch_size,
            tracking_record.pause_ms,
            *tracking_record.migration_job_arguments)

          job_instance
        end

        def fetch_feature_category(job_class)
          if job_class.respond_to?(:feature_category)
            job_class.feature_category.to_s
          else
            Gitlab::BackgroundMigration::BatchedMigrationJob::DEFAULT_FEATURE_CATEGORY
          end
        end
      end
    end
  end
end
