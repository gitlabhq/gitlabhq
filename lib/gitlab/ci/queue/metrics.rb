# frozen_string_literal: true

module Gitlab
  module Ci
    module Queue
      class Metrics
        extend Gitlab::Utils::StrongMemoize

        QUEUE_DURATION_SECONDS_BUCKETS = [1, 3, 10, 30, 60, 300, 900, 1800, 3600].freeze
        QUEUE_ACTIVE_RUNNERS_BUCKETS = [1, 3, 10, 30, 60, 300, 900, 1800, 3600].freeze
        QUEUE_DEPTH_TOTAL_BUCKETS = [1, 2, 3, 5, 8, 16, 32, 50, 100, 250, 500, 1000, 2000, 5000].freeze
        QUEUE_SIZE_TOTAL_BUCKETS = [1, 5, 10, 50, 100, 500, 1000, 2000, 5000, 7500, 10000, 15000, 20000].freeze
        QUEUE_PROCESSING_DURATION_SECONDS_BUCKETS = [0.01, 0.05, 0.1, 0.3, 0.5, 1, 5, 10, 15, 20, 30, 60].freeze

        METRICS_SHARD_TAG_PREFIX = 'metrics_shard::'
        DEFAULT_METRICS_SHARD = 'default'
        JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET = 5

        OPERATION_COUNTERS = [
          :build_can_pick,
          :build_not_pick,
          :build_not_pending,
          :build_queue_push,
          :build_queue_pop,
          :build_temporary_locked,
          :build_conflict_lock,
          :build_conflict_exception,
          :build_conflict_transition,
          :queue_attempt,
          :queue_conflict,
          :queue_iteration,
          :queue_depth_limit,
          :queue_replication_lag,
          :runner_pre_assign_checks_failed,
          :runner_pre_assign_checks_success,
          :runner_queue_tick,
          :shared_runner_build_new,
          :shared_runner_build_done
        ].to_set.freeze

        QUEUE_DEPTH_HISTOGRAMS = [
          :found,
          :not_found,
          :conflict
        ].to_set.freeze

        attr_reader :runner

        def initialize(runner)
          @runner = runner
        end

        def register_failure
          self.class.failed_attempt_counter.increment
          self.class.attempt_counter.increment
        end

        def register_success(job)
          labels = { shared_runner: runner.instance_type?,
                     jobs_running_for_project: jobs_running_for_project(job),
                     shard: DEFAULT_METRICS_SHARD }

          if runner.instance_type?
            shard = runner.tag_list.sort.find { |name| name.starts_with?(METRICS_SHARD_TAG_PREFIX) }
            labels[:shard] = shard.gsub(METRICS_SHARD_TAG_PREFIX, '') if shard
          end

          self.class.job_queue_duration_seconds.observe(labels, Time.current - job.queued_at) unless job.queued_at.nil?
          self.class.attempt_counter.increment
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def jobs_running_for_project(job)
          return '+Inf' unless runner.instance_type?

          # excluding currently started job
          running_jobs_count = job.project.builds.running.where(runner: ::Ci::Runner.instance_type)
                                  .limit(JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET + 1).count - 1
          running_jobs_count < JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET ? running_jobs_count : "#{JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET}+"
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def increment_queue_operation(operation)
          self.class.increment_queue_operation(operation)
        end

        def observe_queue_depth(queue, size)
          return unless Feature.enabled?(:gitlab_ci_builds_queuing_metrics, default_enabled: false)

          if !Rails.env.production? && !QUEUE_DEPTH_HISTOGRAMS.include?(queue)
            raise ArgumentError, "unknown queue depth label: #{queue}"
          end

          self.class.queue_depth_total.observe({ queue: queue }, size.to_f)
        end

        def observe_queue_size(size_proc, runner_type)
          return unless Feature.enabled?(:gitlab_ci_builds_queuing_metrics, default_enabled: false)

          self.class.queue_size_total.observe({ runner_type: runner_type }, size_proc.call.to_f)
        end

        def observe_queue_time(metric, runner_type)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          result = yield

          return result unless Feature.enabled?(:gitlab_ci_builds_queuing_metrics, default_enabled: false)

          seconds = ::Gitlab::Metrics::System.monotonic_time - start_time

          case metric
          when :process
            self.class.queue_iteration_duration_seconds.observe({ runner_type: runner_type }, seconds.to_f)
          when :retrieve
            self.class.queue_retrieval_duration_seconds.observe({ runner_type: runner_type }, seconds.to_f)
          else
            raise ArgumentError unless Rails.env.production?
          end

          result
        end

        def self.increment_queue_operation(operation)
          if !Rails.env.production? && !OPERATION_COUNTERS.include?(operation)
            raise ArgumentError, "unknown queue operation: #{operation}"
          end

          queue_operations_total.increment(operation: operation)
        end

        def self.observe_active_runners(runners_proc)
          return unless Feature.enabled?(:gitlab_ci_builds_queuing_metrics, default_enabled: false)

          queue_active_runners_total.observe({}, runners_proc.call.to_f)
        end

        def self.increment_runner_tick(runner)
          self.new(runner).increment_queue_operation(:runner_queue_tick)
        end

        def self.failed_attempt_counter
          strong_memoize(:failed_attempt_counter) do
            name = :job_register_attempts_failed_total
            comment = 'Counts the times a runner tries to register a job'

            Gitlab::Metrics.counter(name, comment)
          end
        end

        def self.attempt_counter
          strong_memoize(:attempt_counter) do
            name = :job_register_attempts_total
            comment = 'Counts the times a runner tries to register a job'

            Gitlab::Metrics.counter(name, comment)
          end
        end

        def self.job_queue_duration_seconds
          strong_memoize(:job_queue_duration_seconds) do
            name = :job_queue_duration_seconds
            comment = 'Request handling execution time'
            buckets = QUEUE_DURATION_SECONDS_BUCKETS
            labels = {}

            Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end

        def self.queue_operations_total
          strong_memoize(:queue_operations_total) do
            name = :gitlab_ci_queue_operations_total
            comment = 'Counts all the operations that are happening inside a queue'

            Gitlab::Metrics.counter(name, comment)
          end
        end

        def self.queue_depth_total
          strong_memoize(:queue_depth_total) do
            name = :gitlab_ci_queue_depth_total
            comment = 'Size of a CI/CD builds queue in relation to the operation result'
            buckets = QUEUE_DEPTH_TOTAL_BUCKETS
            labels = {}

            Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end

        def self.queue_size_total
          strong_memoize(:queue_size_total) do
            name = :gitlab_ci_queue_size_total
            comment = 'Size of initialized CI/CD builds queue'
            buckets = QUEUE_SIZE_TOTAL_BUCKETS
            labels = {}

            Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end

        def self.queue_iteration_duration_seconds
          strong_memoize(:queue_iteration_duration_seconds) do
            name = :gitlab_ci_queue_iteration_duration_seconds
            comment = 'Time it takes to find a build in CI/CD queue'
            buckets = QUEUE_PROCESSING_DURATION_SECONDS_BUCKETS
            labels = {}

            Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end

        def self.queue_retrieval_duration_seconds
          strong_memoize(:queue_retrieval_duration_seconds) do
            name = :gitlab_ci_queue_retrieval_duration_seconds
            comment = 'Time it takes to execute a SQL query to retrieve builds queue'
            buckets = QUEUE_PROCESSING_DURATION_SECONDS_BUCKETS
            labels = {}

            Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end

        def self.queue_active_runners_total
          strong_memoize(:queue_active_runners_total) do
            name = :gitlab_ci_queue_active_runners_total
            comment = 'The amount of active runners that can process queue in a project'
            buckets = QUEUE_ACTIVE_RUNNERS_BUCKETS
            labels = {}

            Gitlab::Metrics.histogram(name, comment, labels, buckets)
          end
        end
      end
    end
  end
end
