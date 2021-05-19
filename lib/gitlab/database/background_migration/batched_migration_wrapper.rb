# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigrationWrapper
        extend Gitlab::Utils::StrongMemoize

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
        rescue Exception # rubocop:disable Lint/RescueException
          batch_tracking_record.status = :failed

          raise
        ensure
          finish_tracking_execution(batch_tracking_record)
          track_prometheus_metrics(batch_tracking_record)
        end

        private

        def start_tracking_execution(tracking_record)
          tracking_record.update!(attempts: tracking_record.attempts + 1, status: :running, started_at: Time.current, finished_at: nil, metrics: {})
        end

        def execute_batch(tracking_record)
          job_instance = tracking_record.migration_job_class.new

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

        def finish_tracking_execution(tracking_record)
          tracking_record.finished_at = Time.current
          tracking_record.save!
        end

        def track_prometheus_metrics(tracking_record)
          migration = tracking_record.batched_migration
          base_labels = migration.prometheus_labels

          metric_for(:gauge_batch_size).set(base_labels, tracking_record.batch_size)
          metric_for(:gauge_sub_batch_size).set(base_labels, tracking_record.sub_batch_size)
          metric_for(:gauge_interval).set(base_labels, tracking_record.batched_migration.interval)
          metric_for(:gauge_job_duration).set(base_labels, (tracking_record.finished_at - tracking_record.started_at).to_i)
          metric_for(:counter_updated_tuples).increment(base_labels, tracking_record.batch_size)
          metric_for(:gauge_migrated_tuples).set(base_labels, tracking_record.batched_migration.migrated_tuple_count)
          metric_for(:gauge_total_tuple_count).set(base_labels, tracking_record.batched_migration.total_tuple_count)
          metric_for(:gauge_last_update_time).set(base_labels, Time.current.to_i)

          if metrics = tracking_record.metrics
            metrics['timings']&.each do |key, timings|
              summary = metric_for(:histogram_timings)
              labels = base_labels.merge(operation: key)

              timings.each do |timing|
                summary.observe(labels, timing)
              end
            end
          end
        end

        def metric_for(name)
          self.class.metrics[name]
        end

        def self.metrics
          strong_memoize(:metrics) do
            {
              gauge_batch_size: Gitlab::Metrics.gauge(
                :batched_migration_job_batch_size,
                'Batch size for a batched migration job'
              ),
              gauge_sub_batch_size: Gitlab::Metrics.gauge(
                :batched_migration_job_sub_batch_size,
                'Sub-batch size for a batched migration job'
              ),
              gauge_interval: Gitlab::Metrics.gauge(
                :batched_migration_job_interval_seconds,
                'Interval for a batched migration job'
              ),
              gauge_job_duration: Gitlab::Metrics.gauge(
                :batched_migration_job_duration_seconds,
                'Duration for a batched migration job'
              ),
              counter_updated_tuples: Gitlab::Metrics.counter(
                :batched_migration_job_updated_tuples_total,
                'Number of tuples updated by batched migration job'
              ),
              gauge_migrated_tuples: Gitlab::Metrics.gauge(
                :batched_migration_migrated_tuples_total,
                'Total number of tuples migrated by a batched migration'
              ),
              histogram_timings: Gitlab::Metrics.histogram(
                :batched_migration_job_query_duration_seconds,
                'Query timings for a batched migration job',
                {},
                [0.1, 0.25, 0.5, 1, 5].freeze
              ),
              gauge_total_tuple_count: Gitlab::Metrics.gauge(
                :batched_migration_total_tuple_count,
                'Total tuple count the migration needs to touch'
              ),
              gauge_last_update_time: Gitlab::Metrics.gauge(
                :batched_migration_last_update_time_seconds,
                'Unix epoch time in seconds'
              )
            }
          end
        end
      end
    end
  end
end
