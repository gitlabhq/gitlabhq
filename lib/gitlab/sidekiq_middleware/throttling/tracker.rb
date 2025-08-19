# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      class Tracker
        INTERVAL_SECONDS = 60
        TTL = INTERVAL_SECONDS + 60
        LOOKUP_KEY_TTL = 3.days

        def self.throttled_workers
          with_redis do |redis|
            redis.smembers(lookup_key)
          end
        end

        def self.with_redis(&block)
          Gitlab::Redis::QueuesMetadata.with(&block) # rubocop:disable CodeReuse/ActiveRecord -- not ActiveRecord model
        end

        def self.lookup_key
          "sidekiq:throttling:worker:lookup:throttled"
        end

        def initialize(worker_name)
          @worker_name = worker_name
        end

        attr_reader :worker_name

        def record
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            self.class.with_redis do |redis|
              redis.pipelined do |pipeline|
                pipeline.set(cache_key(worker_name, period_key), "true", ex: TTL)
                pipeline.sadd(self.class.lookup_key, worker_name)
                pipeline.expire(self.class.lookup_key, LOOKUP_KEY_TTL)
              end
            end
          end
        end

        def currently_throttled?
          self.class.with_redis do |redis|
            redis.exists?(cache_key(worker_name, period_key)) # rubocop:disable CodeReuse/ActiveRecord -- not ActiveRecord model
          end
        end

        def remove_from_throttled_list!
          self.class.with_redis do |redis|
            redis.srem(self.class.lookup_key, worker_name)
          end
        end

        private

        def period_key(time = Time.current)
          time.to_i.divmod(INTERVAL_SECONDS).first
        end

        def cache_key(worker_name, period_key)
          "sidekiq:throttling:worker:{#{worker_name}}:#{period_key}:throttled"
        end
      end
    end
  end
end
