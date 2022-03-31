# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class PrometheusMetrics
        extend Gitlab::Utils::StrongMemoize

        QUERY_TIMING_BUCKETS = [0.1, 0.25, 0.5, 1, 5].freeze

        def track(job_record)
          migration_record = job_record.batched_migration
          base_labels = migration_record.prometheus_labels

          metric_for(:gauge_batch_size).set(base_labels, job_record.batch_size)
          metric_for(:gauge_sub_batch_size).set(base_labels, job_record.sub_batch_size)
          metric_for(:gauge_interval).set(base_labels, job_record.batched_migration.interval)
          metric_for(:gauge_job_duration).set(base_labels, (job_record.finished_at - job_record.started_at).to_i)
          metric_for(:counter_updated_tuples).increment(base_labels, job_record.batch_size)
          metric_for(:gauge_migrated_tuples).set(base_labels, migration_record.migrated_tuple_count)
          metric_for(:gauge_total_tuple_count).set(base_labels, migration_record.total_tuple_count)
          metric_for(:gauge_last_update_time).set(base_labels, Time.current.to_i)

          track_timing_metrics(base_labels, job_record.metrics)
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
                QUERY_TIMING_BUCKETS
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

        private

        def track_timing_metrics(base_labels, metrics)
          return unless metrics && metrics['timings']

          metrics['timings'].each do |key, timings|
            summary = metric_for(:histogram_timings)
            labels = base_labels.merge(operation: key)

            timings.each do |timing|
              summary.observe(labels, timing)
            end
          end
        end

        def metric_for(name)
          self.class.metrics[name]
        end
      end
    end
  end
end
