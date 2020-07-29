# frozen_string_literal: true

require 'redis'

module Gitlab
  module Instrumentation
    class RedisBase
      class << self
        include ::Gitlab::Utils::StrongMemoize
        include ::Gitlab::Instrumentation::RedisPayload

        # TODO: To be used by https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/395
        # as a 'label' alias.
        def storage_key
          self.name.demodulize.underscore
        end

        def add_duration(duration)
          ::RequestStore[call_duration_key] ||= 0
          ::RequestStore[call_duration_key] += duration
        end

        def add_call_details(duration, args)
          return unless Gitlab::PerformanceBar.enabled_for_request?
          # redis-rb passes an array (e.g. [[:get, key]])
          return unless args.length == 1

          detail_store << {
            cmd: args.first,
            duration: duration,
            backtrace: ::Gitlab::BacktraceCleaner.clean_backtrace(caller)
          }
        end

        def increment_request_count
          ::RequestStore[request_count_key] ||= 0
          ::RequestStore[request_count_key] += 1
        end

        def increment_read_bytes(num_bytes)
          ::RequestStore[read_bytes_key] ||= 0
          ::RequestStore[read_bytes_key] += num_bytes
        end

        def increment_write_bytes(num_bytes)
          ::RequestStore[write_bytes_key] ||= 0
          ::RequestStore[write_bytes_key] += num_bytes
        end

        def get_request_count
          ::RequestStore[request_count_key] || 0
        end

        def read_bytes
          ::RequestStore[read_bytes_key] || 0
        end

        def write_bytes
          ::RequestStore[write_bytes_key] || 0
        end

        def detail_store
          ::RequestStore[call_details_key] ||= []
        end

        def query_time
          query_time = ::RequestStore[call_duration_key] || 0
          query_time.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
        end

        def redis_cluster_validate!(command)
          ::Gitlab::Instrumentation::RedisClusterValidator.validate!(command) if @redis_cluster_validation
        end

        def enable_redis_cluster_validation
          @redis_cluster_validation = true

          self
        end

        def instance_count_request
          @request_counter ||= Gitlab::Metrics.counter(:gitlab_redis_client_requests_total, 'Client side Redis request count, per Redis server')
          @request_counter.increment({ storage: storage_key })
        end

        def instance_count_exception(ex)
          # This metric is meant to give a client side view of how the Redis
          # server is doing. Redis itself does not expose error counts. This
          # metric can be used for Redis alerting and service health monitoring.
          @exception_counter ||= Gitlab::Metrics.counter(:gitlab_redis_client_exceptions_total, 'Client side Redis exception count, per Redis server, per exception class')
          @exception_counter.increment({ storage: storage_key, exception: ex.class.to_s })
        end

        def instance_observe_duration(duration)
          @request_latency_histogram ||= Gitlab::Metrics.histogram(
            :gitlab_redis_client_requests_duration_seconds,
            'Client side Redis request latency, per Redis server, excluding blocking commands',
            {},
            [0.1, 0.5, 0.75, 1]
          )

          @request_latency_histogram.observe({ storage: storage_key }, duration)
        end

        private

        def request_count_key
          strong_memoize(:request_count_key) { build_key(:redis_request_count) }
        end

        def read_bytes_key
          strong_memoize(:read_bytes_key) { build_key(:redis_read_bytes) }
        end

        def write_bytes_key
          strong_memoize(:write_bytes_key) { build_key(:redis_write_bytes) }
        end

        def call_duration_key
          strong_memoize(:call_duration_key) { build_key(:redis_call_duration) }
        end

        def call_details_key
          strong_memoize(:call_details_key) { build_key(:redis_call_details) }
        end

        def build_key(namespace)
          "#{storage_key}_#{namespace}"
        end
      end
    end
  end
end
