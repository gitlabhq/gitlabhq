# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ServerMetrics
      include ::Gitlab::SidekiqMiddleware::MetricsHelper

      # SIDEKIQ_LATENCY_BUCKETS are latency histogram buckets better suited to Sidekiq
      # timeframes than the DEFAULT_BUCKET definition. Defined in seconds.
      # This information is better viewed in logs, but these buckets cover
      # most of the durations for cpu, gitaly, db and elasticsearch
      SIDEKIQ_LATENCY_BUCKETS = [0.1, 0.5, 1, 2.5].freeze

      # These are the buckets we currently use for alerting, we will likely
      # replace these histograms with Application SLIs
      # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1313
      SIDEKIQ_JOB_DURATION_BUCKETS = [10, 300].freeze
      SIDEKIQ_QUEUE_DURATION_BUCKETS = [10, 60].freeze

      # These labels from Gitlab::SidekiqMiddleware::MetricsHelper are included in SLI metrics
      SIDEKIQ_SLI_LABELS = [:worker, :feature_category, :urgency].freeze

      class << self
        include ::Gitlab::SidekiqMiddleware::MetricsHelper

        def metrics
          {
            sidekiq_jobs_cpu_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_cpu_seconds, 'Seconds this Sidekiq job spent on the CPU', {}, SIDEKIQ_LATENCY_BUCKETS),
            sidekiq_jobs_completion_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_completion_seconds, 'Seconds to complete Sidekiq job', {}, SIDEKIQ_JOB_DURATION_BUCKETS),
            sidekiq_jobs_db_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_db_seconds, 'Seconds of database time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
            sidekiq_jobs_gitaly_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_gitaly_seconds, 'Seconds of Gitaly time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS),
            sidekiq_jobs_queue_duration_seconds: ::Gitlab::Metrics.histogram(:sidekiq_jobs_queue_duration_seconds, 'Duration in seconds that a Sidekiq job was queued before being executed', {}, SIDEKIQ_QUEUE_DURATION_BUCKETS),
            sidekiq_redis_requests_duration_seconds: ::Gitlab::Metrics.histogram(:sidekiq_redis_requests_duration_seconds, 'Duration in seconds that a Sidekiq job spent requests a Redis server', {}, Gitlab::Instrumentation::Redis::QUERY_TIME_BUCKETS),
            sidekiq_elasticsearch_requests_duration_seconds: ::Gitlab::Metrics.histogram(:sidekiq_elasticsearch_requests_duration_seconds, 'Duration in seconds that a Sidekiq job spent in requests to an Elasticsearch server', {}, SIDEKIQ_LATENCY_BUCKETS),
            sidekiq_jobs_failed_total: ::Gitlab::Metrics.counter(:sidekiq_jobs_failed_total, 'Sidekiq jobs failed'),
            sidekiq_jobs_retried_total: ::Gitlab::Metrics.counter(:sidekiq_jobs_retried_total, 'Sidekiq jobs retried'),
            sidekiq_jobs_interrupted_total: ::Gitlab::Metrics.counter(:sidekiq_jobs_interrupted_total, 'Sidekiq jobs interrupted'),
            sidekiq_redis_requests_total: ::Gitlab::Metrics.counter(:sidekiq_redis_requests_total, 'Redis requests during a Sidekiq job execution'),
            sidekiq_elasticsearch_requests_total: ::Gitlab::Metrics.counter(:sidekiq_elasticsearch_requests_total, 'Elasticsearch requests during a Sidekiq job execution'),
            sidekiq_running_jobs: ::Gitlab::Metrics.gauge(:sidekiq_running_jobs, 'Number of Sidekiq jobs running', {}, :all),
            sidekiq_concurrency: ::Gitlab::Metrics.gauge(:sidekiq_concurrency, 'Maximum number of Sidekiq jobs', {}, :all),
            sidekiq_mem_total_bytes: ::Gitlab::Metrics.gauge(:sidekiq_mem_total_bytes, 'Number of bytes allocated for both objects consuming an object slot and objects that required a malloc', {}, :all)
          }
        end

        def initialize_process_metrics
          metrics = self.metrics

          metrics[:sidekiq_concurrency].set({}, Sidekiq[:concurrency].to_i)

          return unless ::Feature.enabled?(:sidekiq_job_completion_metric_initialize)

          possible_sli_labels = []
          ::Gitlab::SidekiqConfig.current_worker_queue_mappings.each do |worker, queue|
            worker_class = worker.safe_constantize

            next unless worker_class

            base_labels = create_labels(worker_class, queue, {})
            possible_sli_labels << base_labels.slice(*SIDEKIQ_SLI_LABELS)

            %w[done fail].each do |status|
              metrics[:sidekiq_jobs_completion_seconds].get(base_labels.merge(job_status: status))
            end
          end

          Gitlab::Metrics::SidekiqSlis.initialize_slis!(possible_sli_labels) if ::Feature.enabled?(:sidekiq_execution_application_slis)
        end
      end

      def initialize
        @metrics = self.class.metrics
        @metrics[:sidekiq_load_balancing_count] = ::Gitlab::Metrics.counter(:sidekiq_load_balancing_count, 'Sidekiq jobs with load balancing')
      end

      def call(worker, job, queue)
        # This gives all the sidekiq worker threads a name, so we can recognize them
        # in metrics and can use them in the `ThreadsSampler` for setting a label
        Thread.current.name ||= Gitlab::Metrics::Samplers::ThreadsSampler::SIDEKIQ_WORKER_THREAD_NAME

        labels = create_labels(worker.class, queue, job)
        instrument(job, labels) do
          yield
        end
      end

      protected

      attr_reader :metrics

      def instrument(job, labels)
        queue_duration = ::Gitlab::InstrumentationHelper.queue_duration_for_job(job)

        @metrics[:sidekiq_jobs_queue_duration_seconds].observe(labels, queue_duration) if queue_duration
        @metrics[:sidekiq_running_jobs].increment(labels, 1)

        if job['retry_count'].present?
          @metrics[:sidekiq_jobs_retried_total].increment(labels, 1)
        end

        if job['interrupted_count'].present?
          @metrics[:sidekiq_jobs_interrupted_total].increment(labels, 1)
        end

        job_succeeded = false
        monotonic_time_start = Gitlab::Metrics::System.monotonic_time
        job_thread_cputime_start = get_thread_cputime
        begin
          transaction = Gitlab::Metrics::BackgroundTransaction.new
          transaction.run { yield }
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
          instrumentation = job[:instrumentation] || {}
          @metrics[:sidekiq_jobs_cpu_seconds].observe(labels, job_thread_cputime)
          @metrics[:sidekiq_jobs_completion_seconds].observe(labels, monotonic_time)
          @metrics[:sidekiq_jobs_db_seconds].observe(labels, ActiveRecord::LogSubscriber.runtime / 1000)
          @metrics[:sidekiq_jobs_gitaly_seconds].observe(labels, get_gitaly_time(instrumentation))
          @metrics[:sidekiq_redis_requests_total].increment(labels, get_redis_calls(instrumentation))
          @metrics[:sidekiq_redis_requests_duration_seconds].observe(labels, get_redis_time(instrumentation))
          @metrics[:sidekiq_elasticsearch_requests_total].increment(labels, get_elasticsearch_calls(instrumentation))
          @metrics[:sidekiq_elasticsearch_requests_duration_seconds].observe(labels, get_elasticsearch_time(instrumentation))
          @metrics[:sidekiq_mem_total_bytes].set(labels, get_thread_memory_total_allocations(instrumentation))

          with_load_balancing_settings(job) do |settings|
            load_balancing_labels = {
              load_balancing_strategy: settings['load_balancing_strategy'],
              data_consistency: settings['worker_data_consistency']
            }

            @metrics[:sidekiq_load_balancing_count].increment(labels.merge(load_balancing_labels), 1)
          end

          if ::Feature.enabled?(:sidekiq_execution_application_slis)
            sli_labels = labels.slice(*SIDEKIQ_SLI_LABELS)
            Gitlab::Metrics::SidekiqSlis.record_execution_apdex(sli_labels, monotonic_time) if job_succeeded
            Gitlab::Metrics::SidekiqSlis.record_execution_error(sli_labels, !job_succeeded)
          end
        end
      end

      private

      def with_load_balancing_settings(job)
        keys = %w[load_balancing_strategy worker_data_consistency]
        return unless keys.all? { |k| job.key?(k) }

        yield job.slice(*keys)
      end

      def get_thread_cputime
        defined?(Process::CLOCK_THREAD_CPUTIME_ID) ? Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID) : 0
      end

      def get_redis_time(payload)
        payload.fetch(:redis_duration_s, 0)
      end

      def get_redis_calls(payload)
        payload.fetch(:redis_calls, 0)
      end

      def get_elasticsearch_time(payload)
        payload.fetch(:elasticsearch_duration_s, 0)
      end

      def get_thread_memory_total_allocations(payload)
        payload.fetch(:mem_total_bytes, 0)
      end

      def get_elasticsearch_calls(payload)
        payload.fetch(:elasticsearch_calls, 0)
      end

      def get_gitaly_time(payload)
        payload.fetch(:gitaly_duration_s, 0)
      end
    end
  end
end

Gitlab::SidekiqMiddleware::ServerMetrics.prepend_mod_with('Gitlab::SidekiqMiddleware::ServerMetrics')
