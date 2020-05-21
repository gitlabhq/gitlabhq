# frozen_string_literal: true

require 'redis'

module Gitlab
  module Instrumentation
    module RedisInterceptor
      def call(*args, &block)
        start = Time.now
        super(*args, &block)
      ensure
        duration = (Time.now - start)

        if ::RequestStore.active?
          ::Gitlab::Instrumentation::Redis.increment_request_count
          ::Gitlab::Instrumentation::Redis.add_duration(duration)
          ::Gitlab::Instrumentation::Redis.add_call_details(duration, args)
        end
      end
    end

    class Redis
      REDIS_REQUEST_COUNT = :redis_request_count
      REDIS_CALL_DURATION = :redis_call_duration
      REDIS_CALL_DETAILS = :redis_call_details
      REDIS_READ_BYTES = :redis_read_bytes
      REDIS_WRITE_BYTES = :redis_write_bytes

      # Milliseconds represented in seconds (from 1 to 500 milliseconds).
      QUERY_TIME_BUCKETS = [0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5].freeze

      def self.get_request_count
        ::RequestStore[REDIS_REQUEST_COUNT] || 0
      end

      def self.increment_request_count
        ::RequestStore[REDIS_REQUEST_COUNT] ||= 0
        ::RequestStore[REDIS_REQUEST_COUNT] += 1
      end

      def self.increment_read_bytes(num_bytes)
        ::RequestStore[REDIS_READ_BYTES] ||= 0
        ::RequestStore[REDIS_READ_BYTES] += num_bytes
      end

      def self.increment_write_bytes(num_bytes)
        ::RequestStore[REDIS_WRITE_BYTES] ||= 0
        ::RequestStore[REDIS_WRITE_BYTES] += num_bytes
      end

      def self.read_bytes
        ::RequestStore[REDIS_READ_BYTES] || 0
      end

      def self.write_bytes
        ::RequestStore[REDIS_WRITE_BYTES] || 0
      end

      def self.detail_store
        ::RequestStore[REDIS_CALL_DETAILS] ||= []
      end

      def self.query_time
        query_time = ::RequestStore[REDIS_CALL_DURATION] || 0
        query_time.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
      end

      def self.add_duration(duration)
        ::RequestStore[REDIS_CALL_DURATION] ||= 0
        ::RequestStore[REDIS_CALL_DURATION] += duration
      end

      def self.add_call_details(duration, args)
        return unless Gitlab::PerformanceBar.enabled_for_request?
        # redis-rb passes an array (e.g. [:get, key])
        return unless args.length == 1

        detail_store << {
          cmd: args.first,
          duration: duration,
          backtrace: ::Gitlab::BacktraceCleaner.clean_backtrace(caller)
        }
      end
    end
  end
end

class ::Redis::Client
  prepend ::Gitlab::Instrumentation::RedisInterceptor
end
