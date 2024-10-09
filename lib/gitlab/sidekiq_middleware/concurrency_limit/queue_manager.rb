# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class QueueManager
        attr_reader :redis_key

        def initialize(worker_name, prefix)
          @worker_name = worker_name
          @redis_key = "#{prefix}:throttled_jobs:{#{worker_name.underscore}}"
        end

        def add_to_queue!(args, context)
          with_redis do |redis|
            redis.rpush(@redis_key, serialize(args, context))
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
          with_redis do |redis|
            jobs = next_batch_from_queue(redis, limit: limit)
            break if jobs.empty?

            jobs.each { |job| send_to_processing_queue(deserialize(job)) }
            remove_processed_jobs(redis, limit: jobs.length)

            jobs.length
          end
        end

        private

        def with_redis(&)
          Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- Not active record
        end

        def serialize(args, context)
          { args: args, context: context }.to_json
        end

        def deserialize(json)
          Gitlab::Json.parse(json)
        end

        def send_to_processing_queue(job)
          context = (job['context'] || {}).merge(related_class: self.class.name)

          Gitlab::ApplicationContext.with_raw_context(context) do
            args = job['args']
            Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.resumed_log(@worker_name, args)
            @worker_name.safe_constantize&.perform_async(*args)
          end
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
