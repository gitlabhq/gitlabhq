# frozen_string_literal: true

require 'redis'

module Gitlab
  module Instrumentation
    class RedisBase
      DEFAULT_SHARD_KEY = 'default'

      class << self
        include ::Gitlab::Utils::StrongMemoize
        include ::Gitlab::Instrumentation::RedisPayload

        # TODO: To be used by https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/395
        # as a 'label' alias.
        # The 2 acceptable formats for a demodulized name are: <storage>_shard_<shard> or <storage>.
        def storage_key
          strong_memoize(:storage_key) do
            re = /(?<storage>.+)_shard_.+/
            md = re.match(self.name.demodulize.underscore)
            (md && md[:storage]) || self.name.demodulize.underscore
          end
        end

        def shard_key
          strong_memoize(:shard_key) do
            re = /.+_shard_(?<shard>.+)/
            md = re.match(self.name.demodulize.underscore)
            (md && md[:shard]) || DEFAULT_SHARD_KEY
          end
        end

        def add_duration(duration)
          ::RequestStore[call_duration_key] ||= 0
          ::RequestStore[call_duration_key] += duration
        end

        def add_call_details(duration, commands)
          return unless Gitlab::PerformanceBar.enabled_for_request?

          detail_store << {
            commands: commands,
            duration: duration,
            backtrace: ::Gitlab::BacktraceCleaner.clean_backtrace(caller)
          }
        end

        def increment_request_count(amount = 1)
          ::RequestStore[request_count_key] ||= 0
          ::RequestStore[request_count_key] += amount
        end

        def increment_read_bytes(num_bytes)
          ::RequestStore[read_bytes_key] ||= 0
          ::RequestStore[read_bytes_key] += num_bytes
        end

        def increment_write_bytes(num_bytes)
          ::RequestStore[write_bytes_key] ||= 0
          ::RequestStore[write_bytes_key] += num_bytes
        end

        def increment_cross_slot_request_count(amount = 1)
          ::RequestStore[cross_slots_key] ||= 0
          ::RequestStore[cross_slots_key] += amount
        end

        def increment_allowed_cross_slot_request_count(amount = 1)
          ::RequestStore[allowed_cross_slots_key] ||= 0
          ::RequestStore[allowed_cross_slots_key] += amount
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

        def get_cross_slot_request_count
          ::RequestStore[cross_slots_key] || 0
        end

        def get_allowed_cross_slot_request_count
          ::RequestStore[allowed_cross_slots_key] || 0
        end

        def query_time
          query_time = ::RequestStore[call_duration_key] || 0
          query_time.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
        end

        def redis_cluster_validate!(commands)
          return true unless @redis_cluster_validation

          result = ::Gitlab::Instrumentation::RedisClusterValidator.validate(commands)
          return true if result.nil?

          if !result[:valid] && !result[:allowed] && raise_cross_slot_validation_errors?
            raise RedisClusterValidator::CrossSlotError, "Redis command #{result[:command_name]} arguments hash to different slots. See https://docs.gitlab.com/ee/development/redis.html#multi-key-commands"
          end

          increment_allowed_cross_slot_request_count if result[:allowed] && !result[:valid]

          result[:valid] || result[:allowed]
        end

        def enable_redis_cluster_validation
          @redis_cluster_validation = true

          self
        end

        def instance_count_request(amount = 1)
          @request_counter ||= Gitlab::Metrics.counter(:gitlab_redis_client_requests_total, 'Client side Redis request count, per Redis server')
          @request_counter.increment(storage_labels, amount)
        end

        def instance_count_pipelined_request(size)
          @pipeline_size_histogram ||= Gitlab::Metrics.histogram(
            :gitlab_redis_client_requests_pipelined_commands,
            'Client side Redis request pipeline size, per Redis server',
            {},
            [10, 100, 1000, 10_000]
          )
          @pipeline_size_histogram.observe(storage_labels, size)
        end

        def instance_count_exception(ex)
          # This metric is meant to give a client side view of how the Redis
          # server is doing. Redis itself does not expose error counts. This
          # metric can be used for Redis alerting and service health monitoring.
          @exception_counter ||= Gitlab::Metrics.counter(:gitlab_redis_client_exceptions_total, 'Client side Redis exception count, per Redis server, per exception class')
          @exception_counter.increment(storage_labels.merge(exception: ex.class.to_s))
        end

        def instance_count_connection_exception(ex)
          @connection_exception_counter ||= Gitlab::Metrics.counter(:gitlab_redis_client_connection_exceptions_total, 'Client side Redis connection exception count, per Redis server, per exception class')
          @connection_exception_counter.increment(storage_labels.merge(exception: ex.class.to_s))
        end

        def instance_count_cluster_redirection(ex)
          # This metric is meant to give a client side view of how often are commands
          # redirected to the right node, especially during resharding..
          # This metric can be used for Redis alerting and service health monitoring.
          @redirection_counter ||= Gitlab::Metrics.counter(:gitlab_redis_client_redirections_total, 'Client side Redis Cluster redirection count, per Redis node, per slot')
          @redirection_counter.increment(decompose_redirection_message(ex.message).merge(storage_labels))
        end

        def instance_count_cluster_pipeline_redirection(ex)
          @pipeline_redirection_histogram ||= Gitlab::Metrics.histogram(
            :gitlab_redis_client_pipeline_redirections_count,
            'Client side Redis Cluster pipeline redirection counts per pipeline',
            {},
            [10, 100, 250, 500]
          )

          # RedisClient::Cluster::Pipeline::RedirectionNeeded has `replies` and `indices`.
          # The latter is a list of redirection indices which indicates the volume of redirections per pipeline.
          @pipeline_redirection_histogram.observe(storage_labels, (ex.indices && ex.indices.size).to_i)
        end

        def instance_observe_duration(duration)
          @request_latency_histogram ||= Gitlab::Metrics.histogram(
            :gitlab_redis_client_requests_duration_seconds,
            'Client side Redis request latency, per Redis server, excluding blocking commands',
            {},
            [0.1, 0.5, 0.75, 1]
          )

          @request_latency_histogram.observe(storage_labels, duration)
        end

        def log_exception(ex)
          ::Gitlab::ErrorTracking.log_exception(ex, **storage_labels)
        end

        private

        def storage_labels
          { storage: storage_key, storage_shard: shard_key }
        end

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

        def cross_slots_key
          strong_memoize(:cross_slots_key) { build_key(:redis_cross_slot_request_count) }
        end

        def allowed_cross_slots_key
          strong_memoize(:allowed_cross_slots_key) { build_key(:redis_allowed_cross_slot_request_count) }
        end

        def build_key(namespace)
          "#{storage_key}_#{shard_key}_#{namespace}"
        end

        def decompose_redirection_message(err_msg)
          redirection_type, _, target_node_key = err_msg.split
          { redirection_type: redirection_type, target_node_key: target_node_key }
        end

        def raise_cross_slot_validation_errors?
          Rails.env.development? || Rails.env.test?
        end
      end
    end
  end
end
