# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class ConcurrencyLimitService
        # Class for managing queues for deferred workers

        def initialize(worker_name)
          @worker_name = worker_name
          @redis_key = "sidekiq:concurrency_limit:throttled_jobs:{#{worker_name.underscore}}"
        end

        class << self
          def add_to_queue!(worker_name, args, context)
            new(worker_name).add_to_queue!(args, context)
          end

          def has_jobs_in_queue?(worker_name)
            new(worker_name).has_jobs_in_queue?
          end

          def resume_processing!(worker_name, limit:)
            new(worker_name).resume_processing!(limit: limit)
          end

          def queue_size(worker_name)
            new(worker_name).queue_size
          end
        end

        def add_to_queue!(args, context)
          with_redis do |redis|
            redis.rpush(redis_key, serialize(args, context))
          end
        end

        def queue_size
          with_redis { |redis| redis.llen(redis_key) }
        end

        def has_jobs_in_queue?
          queue_size != 0
        end

        def resume_processing!(limit:)
          with_redis do |redis|
            jobs = next_batch_from_queue(redis, limit: limit)
            break if jobs.empty?

            jobs.each { |j| send_to_processing_queue(deserialize(j)) }

            remove_processed_jobs(redis, limit: jobs.length)

            jobs.length
          end
        end

        private

        attr_reader :worker_name, :redis_key

        def with_redis(&blk)
          Gitlab::Redis::SharedState.with(&blk) # rubocop:disable CodeReuse/ActiveRecord -- Not active record
        end

        def serialize(args, context)
          {
            args: args,
            context: context
          }.to_json
        end

        def deserialize(json)
          Gitlab::Json.parse(json)
        end

        def send_to_processing_queue(job)
          context = (job['context'] || {}).merge(related_class: self.class.name)

          Gitlab::ApplicationContext.with_raw_context(context) do
            args = job['args']

            Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance.resumed_log(worker_name, args)

            worker_name.safe_constantize&.perform_async(*args)
          end
        end

        def next_batch_from_queue(redis, limit:)
          return [] unless limit > 0

          redis.lrange(redis_key, 0, limit - 1)
        end

        def remove_processed_jobs(redis, limit:)
          redis.ltrim(redis_key, limit, -1)
        end
      end
    end
  end
end
