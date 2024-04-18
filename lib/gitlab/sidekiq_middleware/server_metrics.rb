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

      # These buckets are only available on self-managed.
      # We have replaced with Application SLIs on GitLab.com.
      # https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/700
      SIDEKIQ_JOB_DURATION_BUCKETS = [10, 300].freeze
      SIDEKIQ_QUEUE_DURATION_BUCKETS = [10, 60].freeze

      # These labels from Gitlab::SidekiqMiddleware::MetricsHelper are included in SLI metrics
      SIDEKIQ_SLI_LABELS = [:worker, :feature_category, :urgency, :external_dependencies, :queue, :destination_shard_redis, :db_config_name].freeze

      class << self
        include ::Gitlab::SidekiqMiddleware::MetricsHelper

        def metrics
          metrics = {
            sidekiq_jobs_retried_total: ::Gitlab::Metrics.counter(:sidekiq_jobs_retried_total, 'Sidekiq jobs retried'),
            sidekiq_jobs_interrupted_total: ::Gitlab::Metrics.counter(:sidekiq_jobs_interrupted_total, 'Sidekiq jobs interrupted'),
            sidekiq_redis_requests_total: ::Gitlab::Metrics.counter(:sidekiq_redis_requests_total, 'Redis requests during a Sidekiq job execution'),
            sidekiq_elasticsearch_requests_total: ::Gitlab::Metrics.counter(:sidekiq_elasticsearch_requests_total, 'Elasticsearch requests during a Sidekiq job execution'),
            sidekiq_running_jobs: ::Gitlab::Metrics.gauge(:sidekiq_running_jobs, 'Number of Sidekiq jobs running', {}, :all),
            sidekiq_concurrency: ::Gitlab::Metrics.gauge(:sidekiq_concurrency, 'Maximum number of Sidekiq jobs', {}, :all),
            sidekiq_mem_total_bytes: ::Gitlab::Metrics.gauge(:sidekiq_mem_total_bytes, 'Number of bytes allocated for both objects consuming an object slot and objects that required a malloc', {}, :all)
          }

          if Feature.enabled?(:emit_sidekiq_histogram_metrics, type: :ops)
            metrics[:sidekiq_jobs_completion_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_jobs_completion_seconds, 'Seconds to complete Sidekiq job', {}, SIDEKIQ_JOB_DURATION_BUCKETS)
            metrics[:sidekiq_jobs_queue_duration_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_jobs_queue_duration_seconds, 'Duration in seconds that a Sidekiq job was queued before being executed', {}, SIDEKIQ_QUEUE_DURATION_BUCKETS)
            metrics[:sidekiq_jobs_failed_total] = ::Gitlab::Metrics.counter(:sidekiq_jobs_failed_total, 'Sidekiq jobs failed')

            # resource usage
            metrics[:sidekiq_jobs_cpu_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_jobs_cpu_seconds, 'Seconds this Sidekiq job spent on the CPU', {}, SIDEKIQ_LATENCY_BUCKETS)
            metrics[:sidekiq_jobs_db_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_jobs_db_seconds, 'Seconds of database time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS)
            metrics[:sidekiq_jobs_gitaly_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_jobs_gitaly_seconds, 'Seconds of Gitaly time to run Sidekiq job', {}, SIDEKIQ_LATENCY_BUCKETS)
            metrics[:sidekiq_redis_requests_duration_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_redis_requests_duration_seconds, 'Duration in seconds that a Sidekiq job spent in requests to a Redis server', {}, Gitlab::Instrumentation::Redis::QUERY_TIME_BUCKETS)
            metrics[:sidekiq_elasticsearch_requests_duration_seconds] = ::Gitlab::Metrics.histogram(:sidekiq_elasticsearch_requests_duration_seconds, 'Duration in seconds that a Sidekiq job spent in requests to an Elasticsearch server', {}, SIDEKIQ_LATENCY_BUCKETS)
          else
            # These metrics are used in GitLab.com dashboards
            metrics[:sidekiq_jobs_completion_seconds_sum] = ::Gitlab::Metrics.counter(:sidekiq_jobs_completion_seconds_sum, 'Total of seconds to complete Sidekiq job')
            metrics[:sidekiq_jobs_completion_count] = ::Gitlab::Metrics.counter(:sidekiq_jobs_completion_count, 'Number of Sidekiq jobs completed')

            # resource usage sums
            metrics[:sidekiq_jobs_cpu_seconds_sum] = ::Gitlab::Metrics.counter(:sidekiq_jobs_cpu_seconds_sum, 'Total seconds this Sidekiq job spent on the CPU')
            metrics[:sidekiq_jobs_db_seconds_sum] = ::Gitlab::Metrics.counter(:sidekiq_jobs_db_seconds_sum, 'Total seconds of database time to run Sidekiq job')
            metrics[:sidekiq_jobs_gitaly_seconds_sum] = ::Gitlab::Metrics.counter(:sidekiq_jobs_gitaly_seconds_sum, 'Total seconds Gitaly time to run Sidekiq job')
            metrics[:sidekiq_redis_requests_duration_seconds_sum] = ::Gitlab::Metrics.counter(:sidekiq_redis_requests_duration_seconds_sum, 'Total duration in seconds that a Sidekiq job spent in requests to a Redis server')
            metrics[:sidekiq_elasticsearch_requests_duration_seconds_sum] = ::Gitlab::Metrics.counter(:sidekiq_elasticsearch_requests_duration_seconds_sum, 'Total duration in seconds that a Sidekiq job spent in requests to an Elasticsearch server')
          end

          metrics
        end

        def initialize_process_metrics
          metrics = self.metrics

          metrics[:sidekiq_concurrency].set({}, Sidekiq.default_configuration[:concurrency].to_i)

          possible_sli_labels = []
          ::Gitlab::SidekiqConfig.current_worker_queue_mappings.each do |worker, queue|
            worker_class = worker.safe_constantize

            next unless worker_class

            base_labels = create_labels(worker_class, queue, {})
            possible_sli_labels << base_labels.slice(*SIDEKIQ_SLI_LABELS)

            next unless Feature.enabled?(:emit_sidekiq_histogram_metrics, type: :ops)

            %w[done fail].each do |status|
              metrics[:sidekiq_jobs_completion_seconds].get(base_labels.merge(job_status: status))
            end
          end

          Gitlab::Metrics::SidekiqSlis.initialize_execution_slis!(possible_sli_labels)
          Gitlab::Metrics::SidekiqSlis.initialize_queueing_slis!(possible_sli_labels)

          return unless Feature.enabled?(:emit_db_transaction_sli_metrics, type: :ops)

          possible_sli_labels_with_db = Gitlab::Database.database_base_models.keys.flat_map do |name|
            possible_sli_labels.map { |l| l.merge(db_config_name: name) }
          end

          Gitlab::Metrics::DatabaseTransactionSlis.initialize_slis!(possible_sli_labels_with_db)
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

        @job = job
        @labels = create_labels(worker.class, queue, job)
        instrument do
          yield
        end
      end

      protected

      attr_reader :metrics

      def instrument
        @queue_duration = ::Gitlab::InstrumentationHelper.queue_duration_for_job(job)

        @metrics[:sidekiq_jobs_queue_duration_seconds]&.observe(labels, queue_duration) if queue_duration

        @metrics[:sidekiq_running_jobs].increment(labels, 1)

        if job['retry_count'].present?
          @metrics[:sidekiq_jobs_retried_total].increment(labels, 1)
        end

        if job['interrupted_count'].present?
          @metrics[:sidekiq_jobs_interrupted_total].increment(labels, 1)
        end

        @job_succeeded = false
        monotonic_time_start = Gitlab::Metrics::System.monotonic_time
        job_thread_cputime_start = get_thread_cputime
        begin
          transaction = Gitlab::Metrics::BackgroundTransaction.new
          transaction.run { yield }
          @job_succeeded = true
        ensure
          monotonic_time_end = Gitlab::Metrics::System.monotonic_time
          job_thread_cputime_end = get_thread_cputime

          @monotonic_time = monotonic_time_end - monotonic_time_start
          @job_thread_cputime = job_thread_cputime_end - job_thread_cputime_start

          @metrics[:sidekiq_running_jobs].increment(labels, -1)

          @instrumentation = job[:instrumentation] || {}

          record_resource_usage_counters

          # job_status: done, fail match the job_status attribute in structured logging
          labels[:job_status] = job_succeeded ? "done" : "fail"

          record_histograms

          @metrics[:sidekiq_redis_requests_total].increment(labels, get_redis_calls(instrumentation))
          @metrics[:sidekiq_elasticsearch_requests_total].increment(labels, get_elasticsearch_calls(instrumentation))
          @metrics[:sidekiq_mem_total_bytes].set(labels, get_thread_memory_total_allocations(instrumentation))

          with_load_balancing_settings(job) do |settings|
            load_balancing_labels = {
              load_balancing_strategy: settings['load_balancing_strategy'],
              data_consistency: settings['worker_data_consistency']
            }

            @metrics[:sidekiq_load_balancing_count].increment(labels.merge(load_balancing_labels), 1)
          end

          @sli_labels = labels.slice(*SIDEKIQ_SLI_LABELS)
          record_execution_sli
          record_queueing_sli
          record_db_txn_sli if Feature.enabled?(:emit_db_transaction_sli_metrics, type: :ops)
        end
      end

      private

      attr_reader :labels, :job, :queue_duration, :job_succeeded, :monotonic_time, :job_thread_cputime, :instrumentation, :sli_labels

      def record_resource_usage_counters
        if Feature.enabled?(:emit_sidekiq_histogram_metrics, type: :ops)
          @metrics[:sidekiq_jobs_failed_total].increment(labels, 1) unless job_succeeded
        else
          @metrics[:sidekiq_jobs_completion_seconds_sum].increment(labels, monotonic_time)
          @metrics[:sidekiq_jobs_completion_count].increment(labels, 1)
          @metrics[:sidekiq_jobs_cpu_seconds_sum].increment(labels, job_thread_cputime)
          @metrics[:sidekiq_jobs_db_seconds_sum].increment(labels, ActiveRecord::LogSubscriber.runtime / 1000)
          @metrics[:sidekiq_jobs_gitaly_seconds_sum].increment(labels, get_gitaly_time(instrumentation))
          @metrics[:sidekiq_redis_requests_duration_seconds_sum].increment(labels, get_redis_time(instrumentation))
          @metrics[:sidekiq_elasticsearch_requests_duration_seconds_sum].increment(labels, get_elasticsearch_time(instrumentation))
        end
      end

      def record_histograms
        @metrics[:sidekiq_jobs_cpu_seconds]&.observe(labels, job_thread_cputime)

        @metrics[:sidekiq_jobs_completion_seconds]&.observe(labels, monotonic_time)

        @metrics[:sidekiq_jobs_db_seconds]&.observe(labels, ActiveRecord::LogSubscriber.runtime / 1000)
        @metrics[:sidekiq_jobs_gitaly_seconds]&.observe(labels, get_gitaly_time(instrumentation))
        @metrics[:sidekiq_redis_requests_duration_seconds]&.observe(labels, get_redis_time(instrumentation))
        @metrics[:sidekiq_elasticsearch_requests_duration_seconds]&.observe(labels, get_elasticsearch_time(instrumentation))
      end

      def record_queueing_sli
        Gitlab::Metrics::SidekiqSlis.record_queueing_apdex(sli_labels, queue_duration) if queue_duration
      end

      def record_execution_sli
        Gitlab::Metrics::SidekiqSlis.record_execution_apdex(sli_labels, monotonic_time) if job_succeeded
        Gitlab::Metrics::SidekiqSlis.record_execution_error(sli_labels, !job_succeeded)
      end

      def record_db_txn_sli
        return if ::Gitlab::SafeRequestStore[Gitlab::Metrics::DatabaseTransactionSlis::REQUEST_STORE_KEY].nil?

        ::Gitlab::SafeRequestStore[Gitlab::Metrics::DatabaseTransactionSlis::REQUEST_STORE_KEY].each do |k, v|
          Gitlab::Metrics::DatabaseTransactionSlis.record_txn_apdex(sli_labels.merge(db_config_name: k), v)
        end
      end

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
