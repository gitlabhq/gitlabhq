# frozen_string_literal: true

module Gitlab
  module Instrumentation
    # Aggregates Redis measurements from different request storage sources.
    class Redis
      ActionCable = Class.new(RedisBase)
      Cache = Class.new(RedisBase).enable_redis_cluster_validation
      Queues = Class.new(RedisBase)
      SharedState = Class.new(RedisBase).enable_redis_cluster_validation
      TraceChunks = Class.new(RedisBase).enable_redis_cluster_validation

      STORAGES = [ActionCable, Cache, Queues, SharedState, TraceChunks].freeze

      # Milliseconds represented in seconds (from 1 millisecond to 2 seconds).
      QUERY_TIME_BUCKETS = [0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2].freeze

      class << self
        include ::Gitlab::Instrumentation::RedisPayload

        def storage_key
          nil
        end

        def payload
          super.merge(*STORAGES.flat_map(&:payload))
        end

        def detail_store
          STORAGES.flat_map do |storage|
            storage.detail_store.map { |details| details.merge(storage: storage.name.demodulize) }
          end
        end

        %i[get_request_count query_time read_bytes write_bytes].each do |method|
          define_method method do
            STORAGES.sum(&method)
          end
        end
      end
    end
  end
end
