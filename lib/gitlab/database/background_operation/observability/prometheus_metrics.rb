# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observability
        class PrometheusMetrics
          extend Gitlab::Utils::StrongMemoize

          QUERY_TIMING_BUCKETS = [0.1, 0.25, 0.5, 1, 5].freeze

          def self.metrics
            strong_memoize(:metrics) do
              {
                gauge_batch_size: Gitlab::Metrics.gauge(
                  :background_operation_job_batch_size,
                  'Batch size for a background operation job'
                ),
                gauge_sub_batch_size: Gitlab::Metrics.gauge(
                  :background_operation_job_sub_batch_size,
                  'Sub-batch size for a background operation job'
                ),
                gauge_interval: Gitlab::Metrics.gauge(
                  :background_operation_job_interval_seconds,
                  'Interval for a background operation job'
                ),
                gauge_job_duration: Gitlab::Metrics.gauge(
                  :background_operation_job_duration_seconds,
                  'Duration for a background operation job'
                ),
                counter_updated_tuples: Gitlab::Metrics.counter(
                  :background_operation_job_updated_tuples_total,
                  'Number of tuples updated by background operation job'
                ),
                histogram_timings: Gitlab::Metrics.histogram(
                  :background_operation_job_query_duration_seconds,
                  'Query timings for a background operation job',
                  {},
                  QUERY_TIMING_BUCKETS
                ),
                gauge_migrated_tuples: Gitlab::Metrics.gauge(
                  :background_operation_worker_migrated_tuples_total,
                  'Total number of tuples migrated by a background operation'
                ),
                gauge_total_tuple_count: Gitlab::Metrics.gauge(
                  :background_operation_worker_total_tuple_count,
                  'Total tuple count the background operation worker needs to process'
                ),
                gauge_last_update_time: Gitlab::Metrics.gauge(
                  :background_operation_worker_last_update_time_seconds,
                  'Unix epoch time in seconds'
                )
              }
            end
          end

          def track(job)
            worker = job.worker
            labels = worker.prometheus_labels

            metric_for(:gauge_batch_size).set(labels, job.batch_size.to_i)
            metric_for(:gauge_sub_batch_size).set(labels, job.sub_batch_size.to_i)
            metric_for(:gauge_interval).set(labels, worker.interval.to_i)
            metric_for(:counter_updated_tuples).increment(labels, job.batch_size.to_i)
            metric_for(:gauge_migrated_tuples).set(labels, worker.migrated_tuple_count)
            metric_for(:gauge_total_tuple_count).set(labels, worker.total_tuple_count.to_i)
            metric_for(:gauge_last_update_time).set(labels, Time.current.to_i)

            if job.started_at && job.finished_at
              metric_for(:gauge_job_duration).set(labels, (job.finished_at - job.started_at).to_i)
            end

            track_timing_metrics(labels, job.metrics)
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
end
