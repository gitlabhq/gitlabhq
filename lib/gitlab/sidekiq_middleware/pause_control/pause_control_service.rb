# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      class PauseControlService
        # Class for managing queues for paused workers
        # When a worker is paused all jobs are saved in a separate sorted sets in redis
        LIMIT = 1000
        PROJECT_CONTEXT_KEY = "#{Gitlab::ApplicationContext::LOG_KEY}.project".freeze

        def initialize(worker_name)
          @worker_name = worker_name

          worker_name = @worker_name.underscore
          @redis_set_key = "sidekiq:pause_control:paused_jobs:zset:{#{worker_name}}"
          @redis_score_key = "sidekiq:pause_control:paused_jobs:score:{#{worker_name}}"
        end

        class << self
          def add_to_waiting_queue!(worker_name, args, context)
            new(worker_name).add_to_waiting_queue!(args, context)
          end

          def has_jobs_in_waiting_queue?(worker_name)
            new(worker_name).has_jobs_in_waiting_queue?
          end

          def resume_processing!(worker_name)
            new(worker_name).resume_processing!
          end

          def queue_size(worker_name)
            new(worker_name).queue_size
          end
        end

        def add_to_waiting_queue!(args, context)
          with_redis do |redis|
            redis.zadd(redis_set_key, generate_unique_score(redis), serialize(args, context))
          end
        end

        def queue_size
          with_redis { |redis| redis.zcard(redis_set_key) }
        end

        def has_jobs_in_waiting_queue?
          with_redis { |redis| redis.exists?(redis_set_key) } # rubocop:disable CodeReuse/ActiveRecord
        end

        def resume_processing!(iterations: 1)
          with_redis do |redis|
            iterations.times do
              jobs_with_scores = next_batch_from_waiting_queue(redis)
              break if jobs_with_scores.empty?

              parsed_jobs = jobs_with_scores.map { |j, _| deserialize(j) }

              parsed_jobs.each { |j| send_to_processing_queue(j) }

              remove_jobs_from_waiting_queue(redis, jobs_with_scores)
            end

            size = queue_size
            redis.del(redis_score_key, redis_set_key) if size == 0

            size
          end
        end

        private

        attr_reader :worker_name, :redis_set_key, :redis_score_key

        def with_redis(&blk)
          Gitlab::Redis::SharedState.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
        end

        def serialize(args, context)
          {
            args: args,
            # Only include part of the context that would not prevent deduplication
            context: context.slice(PROJECT_CONTEXT_KEY)
          }.to_json
        end

        def deserialize(json)
          Gitlab::Json.parse(json)
        end

        def send_to_processing_queue(job)
          Gitlab::ApplicationContext.with_raw_context(job['context']) do
            args = job['args']

            Gitlab::SidekiqLogging::PauseControlLogger.instance.resumed_log(worker_name, args)

            worker_name.safe_constantize&.perform_async(*args)
          end
        end

        def generate_unique_score(redis)
          redis.incr(redis_score_key)
        end

        def next_batch_from_waiting_queue(redis)
          redis.zrangebyscore(redis_set_key, '-inf', '+inf', limit: [0, LIMIT], with_scores: true)
        end

        def remove_jobs_from_waiting_queue(redis, jobs_with_scores)
          first_score = jobs_with_scores.first.last
          last_score = jobs_with_scores.last.last
          redis.zremrangebyscore(redis_set_key, first_score, last_score)
        end
      end
    end
  end
end
