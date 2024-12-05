# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class QueueManager
        include ExclusiveLeaseGuard

        LEASE_TIMEOUT = 10.seconds
        RESUME_PROCESSING_BATCH_SIZE = 1_000

        attr_reader :redis_key, :metadata_key, :worker_name

        def initialize(worker_name:, prefix:)
          @worker_name = worker_name
          @redis_key = "#{prefix}:throttled_jobs:{#{worker_name.underscore}}"
          @metadata_key = "#{prefix}:resume_meta:{#{worker_name.underscore}}"
        end

        def add_to_queue!(job, context)
          with_redis do |redis|
            redis.rpush(@redis_key, serialize(job, context))
          end

          deferred_job_counter.increment({ worker: @worker_name })
        end

        def queue_size
          with_redis { |redis| redis.llen(@redis_key) }
        end

        def has_jobs_in_queue?
          queue_size != 0
        end

        def resume_processing!(limit:)
          try_obtain_lease do
            with_redis do |redis|
              jobs = next_batch_from_queue(redis, limit: limit)
              break if jobs.empty?

              bulk_send_to_processing_queue(jobs)
              remove_processed_jobs(redis, limit: jobs.length)

              jobs.length
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

        def with_redis(&)
          Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- Not active record
        end

        def serialize(job, context)
          {
            args: job['args'],
            context: context,
            buffered_at: Time.now.utc.to_f,
            wal_locations: job['wal_locations']
          }.to_json
        end

        def deserialize(json)
          Gitlab::Json.parse(json)
        end

        def bulk_send_to_processing_queue(jobs)
          return if worker_klass.nil?

          jobs.each_slice(RESUME_PROCESSING_BATCH_SIZE) do |batch|
            args_list = prepare_and_store_metadata(batch)
            Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.resumed_log(worker_name, args_list)
            worker_klass.bulk_perform_async(args_list) # rubocop:disable Scalability/BulkPerformWithContext -- context is set separately in SidekiqMiddleware::ConcurrencyLimit::Resume
          end
        end

        def prepare_and_store_metadata(jobs)
          queue = Queue.new
          args_list = []
          jobs.map! do |job|
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
            'concurrency_limit_buffered_at' => job['buffered_at'],
            'concurrency_limit_resume' => true,
            'wal_locations' => job['wal_locations']
          }.merge(job['context'])
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
      end
    end
  end
end
