# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module UsageDataCounters
    module RedisCounter
      include Gitlab::Utils::StrongMemoize

      # This file overrides (or aliases) some keys for legacy Redis metric counters to delay migrating them to new
      # names for now, because doing that in bulk will be a lot easier.
      KEY_OVERRIDES_PATH = Rails.root.join('lib/gitlab/usage_data_counters/total_counter_redis_key_overrides.yml')

      def increment(redis_counter_key, expiry: nil)
        if batch_mode?
          batch_key_count[redis_counter_key] += 1
          batch_expires[redis_counter_key] = expiry
          return
        end

        legacy_redis_counter_key = legacy_key(redis_counter_key)

        Gitlab::Redis::SharedState.with do |redis|
          redis.incr(legacy_redis_counter_key)

          unless expiry.nil?
            existing_expiry = redis.ttl(legacy_redis_counter_key) > 0
            redis.expire(legacy_redis_counter_key, expiry) unless existing_expiry
          end
        end
      end

      def increment_by(redis_counter_key, incr, expiry: nil)
        if batch_mode?
          batch_key_count[redis_counter_key] += incr
          batch_expires[redis_counter_key] = expiry
          return
        end

        legacy_redis_counter_key = legacy_key(redis_counter_key)

        Gitlab::Redis::SharedState.with do |redis|
          redis.incrby(legacy_redis_counter_key, incr)

          unless expiry.nil?
            existing_expiry = redis.ttl(legacy_redis_counter_key) > 0
            redis.expire(legacy_redis_counter_key, expiry) unless existing_expiry
          end
        end
      end

      def total_count(redis_counter_key)
        legacy_redis_counter_key = legacy_key(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(legacy_redis_counter_key).to_i }
      end

      def with_batched_redis_writes
        Thread.current[:redis_counter_batch_mode] = true
        yield
      ensure
        Thread.current[:redis_counter_batch_mode] = false
        flush_redis_batch
        Thread.current[:redis_counter_batch_key_count] = nil
        Thread.current[:redis_counter_batch_expires] = nil
      end

      private

      def flush_redis_batch
        batch_key_count.each do |redis_counter_key, count|
          increment_by(redis_counter_key, count, expiry: batch_expires[redis_counter_key])
        end
      end

      def legacy_key(redis_key)
        key_overrides.fetch(redis_key, redis_key)
      end

      def key_overrides
        YAML.safe_load(File.read(KEY_OVERRIDES_PATH))
      end
      strong_memoize_attr :key_overrides

      def batch_mode?
        Thread.current[:redis_counter_batch_mode] == true
      end

      def batch_key_count
        Thread.current[:redis_counter_batch_key_count] ||= Hash.new(0)
      end

      def batch_expires
        Thread.current[:redis_counter_batch_expires] ||= {}
      end
    end
  end
end
