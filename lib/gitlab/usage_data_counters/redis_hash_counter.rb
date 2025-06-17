# frozen_string_literal: true

# WARNING: Do not use module directly. Use InternalEvents.track_event instead.
# https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/

module Gitlab
  module UsageDataCounters
    module RedisHashCounter
      def hash_increment(redis_counter_key, hash_key, expiry: nil)
        Gitlab::Redis::SharedState.with do |redis|
          redis.hincrby(redis_counter_key, hash_key, 1)

          unless expiry.nil?
            existing_expiry = redis.ttl(redis_counter_key) > 0
            redis.expire(redis_counter_key, expiry) unless existing_expiry
          end
        end
      end

      def get_hash(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.hgetall(redis_counter_key).transform_values(&:to_i) }
      end
    end
  end
end
