# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ServerMetrics
      include ::Gitlab::SidekiqMiddleware::MetricsHelper

      # SIDEKIQ_LATENCY_BUCKETS are latency histogram buckets better suited to Sidekiq
      # timeframes than the DEFAULT_BUCKET definition. Defined in seconds.
      SIDEKIQ_LATENCY_BUCKETS = [0.1, 0.25, 0.5, 1, 2.5, 5, 10, 60, 300, 600].freeze

      def initialize
        @metrics = init_metrics

        @metrics[:sidekiq_concurrency].set({}, Sidekiq.options[:concurrency].to_i)
      end

      def call(worker, job, queue)
        # This gives all the sidekiq worker threads a name, so we can recognize them
        # in metrics and can use them in the `ThreadsSampler` for setting a label
        Thread.current.name ||= Gitlab::Metrics::Samplers::ThreadsSampler::SIDEKIQ_WORKER_THREAD_NAME

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
          @metrics[:sidekiq_jobs_db_seconds].observe(labels, ActiveRecord::LogSubscriber.runtime / 1000)
          @metrics[:sidekiq_jobs_gitaly_seconds].observe(labels, get_gitaly_time(job))
          @metrics[:sidekiq_redis_requests_total].increment(labels, get_redis_calls(job))
          @metrics[:sidekiq_redis_requests_duration_seconds].observe(labels, get_redis_time(job))
          @metrics[:sidekiq_elasticsearch_requests_total].increment(labels, get_elasticsearch_calls(job))
          @metrics[:sidekiq_elasticsearch_requests_duration_seconds].observe(labels, get_elasticsearch_time(job))
        end
      end

      private

      def init_metrics
        {
          sidekiq_jobs_cpu_seconds:                ::Gitlab::Metrics.histogram(:sidekiq_jobs_cpu_seconds, 'Seconds of cpu time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_completion_seconds:         ::Gitlab::Metrics.histogram(:sidekiq_jobs_completion_seconds, 'Seconds to complete Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_db_seconds:                 ::Gitlab::Metrics.histogram(:sidekiq_jobs_db_seconds, 'Seconds of database time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_gitaly_seconds:             ::Gitlab::Metrics.histogram(:sidekiq_jobs_gitaly_seconds, 'Seconds of Gitaly time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_queue_duration_seconds:     ::Gitlab::Metrics.histogram(:sidekiq_jobs_queue_duration_seconds, 'Duration in seconds that a Sidekiq job was queued before being executed', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_redis_requests_duration_seconds: ::Gitlab::Metrics.histogram(:sidekiq_redis_requests_duration_seconds, 'Duration in seconds that a Sidekiq job spent requests a Redis server', {}, Gitlab::Instrumentation::Redis::QUERY_TIME_BUCKETS),
          sidekiq_elasticsearch_requests_duration_seconds: ::Gitlab::Metrics.histogram(:sidekiq_elasticsearch_requests_duration_seconds, 'Duration in seconds that a Sidekiq job spent in requests to an Elasticsearch server', {}, SIDEKIQ_LATENCY_BUCKETS),
          sidekiq_jobs_failed_total:               ::Gitlab::Metrics.counter(:sidekiq_jobs_failed_total, 'Sidekiq jobs failed'),
          sidekiq_jobs_retried_total:              ::Gitlab::Metrics.counter(:sidekiq_jobs_retried_total, 'Sidekiq jobs retried'),
          sidekiq_redis_requests_total:            ::Gitlab::Metrics.counter(:sidekiq_redis_requests_total, 'Redis requests during a Sidekiq job execution'),
          sidekiq_elasticsearch_requests_total:    ::Gitlab::Metrics.counter(:sidekiq_elasticsearch_requests_total, 'Elasticsearch requests during a Sidekiq job execution'),
          sidekiq_running_jobs:                    ::Gitlab::Metrics.gauge(:sidekiq_running_jobs, 'Number of Sidekiq jobs running', {}, :all),
          sidekiq_concurrency:                     ::Gitlab::Metrics.gauge(:sidekiq_concurrency, 'Maximum number of Sidekiq jobs', {}, :all)
        }
      end

      def get_thread_cputime
        defined?(Process::CLOCK_THREAD_CPUTIME_ID) ? Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID) : 0
      end

      def get_redis_time(job)
        job.fetch(:redis_duration_s, 0)
      end

      def get_redis_calls(job)
        job.fetch(:redis_calls, 0)
      end

      def get_elasticsearch_time(job)
        job.fetch(:elasticsearch_duration_s, 0)
      end

      def get_elasticsearch_calls(job)
        job.fetch(:elasticsearch_calls, 0)
      end

      def get_gitaly_time(job)
        job.fetch(:gitaly_duration_s, 0)
      end
    end
  end
end
