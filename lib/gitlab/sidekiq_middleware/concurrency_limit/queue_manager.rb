# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class QueueManager
        include ExclusiveLeaseGuard
        include Gitlab::ExclusiveLeaseHelpers

        MAX_PROCESSING_TIME = 5.minutes
        LEASE_TIMEOUT = MAX_PROCESSING_TIME + 2.seconds
        MAX_BATCH_SIZE = 5_000
        # Bounded wait for the shared lease before drop_jobs! gives up (admin can retry).
        DROP_LOCK_RETRIES = 10
        DROP_LOCK_SLEEP = 0.5.seconds
        NON_TRANSIENT_ERRORS = [
          Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError,
          JSON::ParserError
        ].freeze

        # Size-limiter compression markers replayed onto the resumed job so the
        # server-side middleware decompresses its still-compressed `args`.
        PRESERVED_JOB_KEYS = [
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::COMPRESSED_KEY,
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::ORIGINAL_SIZE_KEY
        ].freeze

        attr_reader :redis_key, :metadata_key, :worker_name

        def initialize(worker_name:, prefix:)
          @worker_name = worker_name
          @redis_key = "#{prefix}:throttled_jobs:{#{worker_name.underscore}}"
          @metadata_key = "#{prefix}:resume_meta:{#{worker_name.underscore}}"
          @drop_request_key = "#{prefix}:drop_requested:{#{worker_name.underscore}}"
        end

        def add_to_queue!(job, context)
          with_redis do |redis|
            redis.rpush(@redis_key, serialize(job, context))
          end

          deferred_job_counter.increment({ worker: @worker_name })
        end

        # Removes deferred jobs from this worker's queue whose context matches the metadata.
        #
        # @param context_metadata [Hash] application-context metadata to match against each job
        # @param timeout [Numeric] seconds budget before stopping early
        # @return [Hash] :completed flag and :deleted_jobs count
        # @see #resume_processing!
        def drop_jobs!(context_metadata, timeout:)
          # Skip the drop-request/lock handshake when there is nothing to remove: callers may
          # iterate over every worker routed to a queue, and most deferred queues are empty.
          return { completed: true, deleted_jobs: 0 } unless has_jobs_in_queue?

          start_time = monotonic_time
          completed = false
          deleted = 0

          # Signal intent so resume_processing! yields the shared lease, then acquire the same
          # lease before mutating: resume trims from the head by position (ltrim) while we remove
          # by value (lrem), which could otherwise drop an unprocessed job. The flag TTL matches
          # the operation budget so it covers the whole run and self-heals if this process dies.
          request_drop!(timeout)

          in_lock(lease_key, ttl: LEASE_TIMEOUT, retries: DROP_LOCK_RETRIES, sleep_sec: DROP_LOCK_SLEEP) do
            completed = true

            with_redis do |redis|
              # We hold the lease, so we are the only remover: track deletions locally instead of
              # inferring from llen, which concurrent add_to_queue! rpushes would inflate (causing
              # range_start to overshoot and skip unexamined entries).
              deleted_size = 0
              page = 0

              loop do
                range_start = (page * MAX_BATCH_SIZE) - deleted_size
                entries = redis.lrange(@redis_key, range_start, range_start + MAX_BATCH_SIZE - 1)
                break if entries.empty?

                page += 1
                timed_out = false
                entries.each do |job_json|
                  if timeout_exceeded?(start_time, timeout)
                    completed = false
                    timed_out = true
                    break
                  end

                  job = deserialize(job_json)
                  next unless job_matches?(job, context_metadata)

                  deleted += redis.lrem(@redis_key, 1, job_json)
                rescue ::JSON::ParserError
                  next
                end

                break if timed_out

                deleted_size = deleted
              end
            end
          end

          { completed: completed, deleted_jobs: deleted }
        rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
          # Resume is actively processing this queue; the caller can retry.
          { completed: false, deleted_jobs: deleted }
        ensure
          clear_drop_request!
        end

        def queue_size
          with_redis { |redis| redis.llen(@redis_key) }
        end

        def has_jobs_in_queue?
          queue_size != 0
        end

        def resume_processing!
          # Yield to a pending drop_jobs! request so an admin purge is not starved while we hold
          # the lease across a long resume run.
          return 0 if drop_requested?

          try_obtain_lease do
            with_redis do |redis|
              unless Feature.enabled?(:concurrency_limit_eager_resume_processing, :instance, type: :ops)
                resumed_jobs_count = resume_processing_once!(redis)
                break resumed_jobs_count
              end

              deadline = MAX_PROCESSING_TIME.from_now
              total_resumed_jobs = 0
              while deadline.future?
                break unless renew_lease!
                break if drop_requested?

                resumed_jobs_count = resume_processing_once!(redis)
                break if resumed_jobs_count == 0

                total_resumed_jobs += resumed_jobs_count
              end
              total_resumed_jobs
            end
          end
        end

        private

        def lease_timeout
          LEASE_TIMEOUT
        end

        def lease_key
          @lease_key ||= "concurrency_limit:queue_manager:{#{worker_name.underscore}}"
        end

        def lease_taken_log_level
          :info
        end

        # Signals that an admin {#drop_jobs!} wants this worker's queue, so {#resume_processing!} yields.
        #
        # @param ttl [Numeric] seconds the flag lives; matches the drop budget so it covers the run
        # @see #resume_processing!
        def request_drop!(ttl)
          with_redis { |redis| redis.set(@drop_request_key, true, ex: [ttl.ceil, 1].max) }
        end

        # Whether an admin {#drop_jobs!} is waiting for this worker's queue.
        #
        # @return [Boolean]
        # @see #drop_jobs!
        def drop_requested?
          with_redis { |redis| redis.exists?(@drop_request_key) } # rubocop:disable CodeReuse/ActiveRecord -- Redis, not ActiveRecord
        end

        # Clears the drop-requested flag once the admin {#drop_jobs!} has finished.
        #
        # @see #drop_jobs!
        def clear_drop_request!
          with_redis { |redis| redis.del(@drop_request_key) }
        end

        def resume_processing_once!(redis)
          jobs = next_batch_from_queue(redis, limit: num_jobs_to_resume)
          return 0 if jobs.empty?

          begin
            bulk_send_to_processing_queue(jobs)
          rescue StandardError => e
            if non_transient_error?(e)
              send_jobs_individually(jobs)
              return jobs.length
            end

            raise
          end

          remove_processed_jobs(redis, limit: jobs.length)

          jobs.length
        end

        def non_transient_error?(error)
          NON_TRANSIENT_ERRORS.any? { |klass| error.is_a?(klass) }
        end

        def send_jobs_individually(jobs)
          return 0 if worker_klass.nil?

          enqueued = 0
          jobs.each do |job|
            bulk_send_to_processing_queue([job])
            enqueued += 1
          rescue StandardError => e
            raise unless non_transient_error?(e)

            log_dropped_job(job, e)
            dropped_job_counter.increment({ worker: @worker_name })
          end

          with_redis do |redis|
            remove_processed_jobs(redis, limit: jobs.length)
          end

          enqueued
        end

        def log_dropped_job(job, error)
          Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.dropped_poison_job_log(worker_name, job, error)
        end

        def num_jobs_to_resume
          limit = worker_limit
          if limit > 0
            limit - concurrent_worker_count - pending_resumed_jobs_count
          else
            MAX_BATCH_SIZE
          end
        end

        def worker_limit
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.current_limit(worker_name)
        end

        def concurrent_worker_count
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.concurrent_worker_count(worker_name)
        end

        def pending_resumed_jobs_count
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.pending_resumed_jobs_count(worker_name)
        end

        def track_pending_resumed_jobs(count)
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.track_pending_resumed_jobs(worker_name,
            count)
        end

        def untrack_pending_resumed_job(count)
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.untrack_pending_resumed_job(worker_name,
            count)
        end

        def with_redis(&)
          Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- Not active record
        end

        def serialize(job, context)
          {
            args: job['args'],
            jid: job['jid'],
            context: context,
            buffered_at: Time.now.utc.to_f,
            wal_locations: job['wal_locations']
          }.merge(job.slice(*PRESERVED_JOB_KEYS)).to_json
        end

        def deserialize(json)
          Gitlab::Json.parse(json)
        end

        def bulk_send_to_processing_queue(jobs)
          return if worker_klass.nil?

          args_list = prepare_and_store_metadata(jobs)
          Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.batch_resumed_log(worker_name, args_list.length)

          # Track before enqueuing so the counter is set before any resumed job can be picked
          # up and reach track_execution_start (which calls untrack_pending_resumed_job). A job
          # dequeued in the window before this increment would decrement a counter still floored
          # at zero, losing the decrement and leaving the counter permanently inflated.
          track_pending_resumed_jobs(args_list.length)
          begin
            worker_klass.bulk_perform_async(args_list) # rubocop:disable Scalability/BulkPerformWithContext -- context is set separately in SidekiqMiddleware::ConcurrencyLimit::Resume
          rescue StandardError
            # The batch was not enqueued, so release the slots we just reserved. The caller
            # either retries the jobs individually (re-tracking one per job) or leaves them
            # buffered; either way these jobs will never reach track_execution_start.
            untrack_pending_resumed_job(args_list.length)
            raise
          end
        end

        def prepare_and_store_metadata(jobs)
          queue = Queue.new
          args_list = []
          jobs.each do |job|
            deserialized = deserialize(job)
            queue.push(job_metadata(deserialized))
            args_list << deserialized['args']
          end

          # Since bulk_perform_async doesn't support updating job payload one by one,
          # we'll rely on Gitlab::SidekiqMiddleware::ConcurrencyLimit::Resume client middleware
          # to update each job with the required metadata.
          Gitlab::SafeRequestStore.write(metadata_key, queue)
          args_list
        end

        def job_metadata(job)
          {
            'jid' => job['jid'],
            'concurrency_limit_buffered_at' => job['buffered_at'],
            'concurrency_limit_resume' => true,
            'wal_locations' => job['wal_locations']
          }.merge(job['context']).merge(job.slice(*PRESERVED_JOB_KEYS))
        end

        def worker_klass
          worker_name.safe_constantize
        end

        def next_batch_from_queue(redis, limit:)
          return [] unless limit > 0

          redis.lrange(@redis_key, 0, limit - 1)
        end

        def remove_processed_jobs(redis, limit:)
          redis.ltrim(@redis_key, limit, -1)
        end

        def deferred_job_counter
          @deferred_job_counter ||= ::Gitlab::Metrics.counter(:sidekiq_concurrency_limit_deferred_jobs_total,
            'Count of jobs deferred by the concurrency limit middleware.')
        end

        def dropped_job_counter
          @dropped_job_counter ||= ::Gitlab::Metrics.counter(:sidekiq_concurrency_limit_dropped_jobs_total,
            'Count of poison jobs dropped from the concurrency limit buffered queue.')
        end

        # Whether a deferred job's stored context matches all given metadata.
        #
        # @param job [Hash] deserialized deferred job payload
        # @param context_metadata [Hash] metadata to match against the job's context
        # @return [Boolean]
        def job_matches?(job, context_metadata)
          return false if context_metadata.empty?

          context = job['context'] || {}
          context_metadata.all? do |key, value|
            # Deferred jobs do not store their class: the queue itself is per-worker.
            key == 'class' ? value == @worker_name : context[key] == value
          end
        end

        # Whether the elapsed time since start_time exceeds the timeout.
        #
        # @param start_time [Float] monotonic timestamp captured at the start
        # @param timeout [Numeric] seconds budget
        # @return [Boolean]
        def timeout_exceeded?(start_time, timeout)
          (monotonic_time - start_time) > timeout
        end

        # Current monotonic clock reading.
        #
        # @return [Float] monotonic time in seconds
        def monotonic_time
          Gitlab::Metrics::System.monotonic_time
        end
      end
    end
  end
end
