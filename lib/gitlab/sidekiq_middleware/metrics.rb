# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class Metrics
      # SIDEKIQ_LATENCY_BUCKETS are latency histogram buckets better suited to Sidekiq
      # timeframes than the DEFAULT_BUCKET definition. Defined in seconds.
      SIDEKIQ_LATENCY_BUCKETS = [0.1, 0.25, 0.5, 1, 2.5, 5, 10, 60, 300, 600].freeze

      TRUE_LABEL = "yes"
      FALSE_LABEL = "no"

      def initialize
        @metrics = init_metrics

        @metrics[:sidekiq_concurrency].set({}, Sidekiq.options[:concurrency].to_i)
      end

      def call(worker, job, queue)
        labels = create_labels(worker.class, queue)
        queue_duration = ::Gitlab::InstrumentationHelper.queue_duration_for_job(job)

        @metrics[:sidekiq_jobs_queue_duration_seconds].observe(labels, queue_duration) if queue_duration
        @metrics[:sidekiq_running_jobs].increment(labels, 1)

        if job['retry_count'].present?
          @metrics[:sidekiq_jobs_retried_total].increment(labels, 1)
        end

        job_succeeded = false
        monotonic_time_start = Gitlab::Metrics::System.monotonic_time
        job_thread_cputime_start = get_thread_cputime
        begin
          yield
          job_succeeded = true
        ensure
          monotonic_time_end = Gitlab::Metrics::System.monotonic_time
          job_thread_cputime_end = get_thread_cputime

          monotonic_time = monotonic_time_end - monotonic_time_start
          job_thread_cputime = job_thread_cputime_end - job_thread_cputime_start

          # sidekiq_running_jobs, sidekiq_jobs_failed_total should not include the job_status label
          @metrics[:sidekiq_running_jobs].increment(labels, -1)
          @metrics[:sidekiq_jobs_failed_total].increment(labels, 1) unless job_succeeded

          # job_status: done, fail match the job_status attribute in structured logging
          labels[:job_status] = job_succeeded ? "done" : "fail"
          @metrics[:sidekiq_jobs_cpu_seconds].observe(labels, job_thread_cputime)
          @metrics[:sidekiq_jobs_completion_seconds].observe(labels, monotonic_time)
        end
      end

      private

      def init_metrics
        {
          sidekiq_jobs_cpu_seconds:            ::Gitlab::Metrics.histogram(:sidekiq_jobs_cpu_seconds, 'Seconds of cpu time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_completion_seconds:     ::Gitlab::Metrics.histogram(:sidekiq_jobs_completion_seconds, 'Seconds to complete Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_queue_duration_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_queue_duration_seconds, 'Duration in seconds that a Sidekiq job was queued before being executed', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_failed_total:           ::Gitlab::Metrics.counter(:sidekiq_jobs_failed_total, 'Sidekiq jobs failed'),
          sidekiq_jobs_retried_total:          ::Gitlab::Metrics.counter(:sidekiq_jobs_retried_total, 'Sidekiq jobs retried'),
          sidekiq_running_jobs:                ::Gitlab::Metrics.gauge(:sidekiq_running_jobs, 'Number of Sidekiq jobs running', {}, :all),
          sidekiq_concurrency:                 ::Gitlab::Metrics.gauge(:sidekiq_concurrency, 'Maximum number of Sidekiq jobs', {}, :all)
        }
      end

      def create_labels(worker_class, queue)
        labels = { queue: queue.to_s, latency_sensitive: FALSE_LABEL, external_dependencies: FALSE_LABEL, feature_category: "", boundary: "" }
        return labels unless worker_class.include? WorkerAttributes

        labels[:latency_sensitive] = bool_as_label(worker_class.latency_sensitive_worker?)
        labels[:external_dependencies] = bool_as_label(worker_class.worker_has_external_dependencies?)

        feature_category = worker_class.get_feature_category
        labels[:feature_category] = feature_category.to_s

        resource_boundary = worker_class.get_worker_resource_boundary
        labels[:boundary] = resource_boundary == :unknown ? "" : resource_boundary.to_s

        labels
      end

      def bool_as_label(value)
        value ? TRUE_LABEL : FALSE_LABEL
      end

      def get_thread_cputime
        defined?(Process::CLOCK_THREAD_CPUTIME_ID) ? Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID) : 0
      end
    end
  end
end
