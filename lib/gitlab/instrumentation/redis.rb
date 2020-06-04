# frozen_string_literal: true

module Gitlab
  module Instrumentation
    # Aggregates Redis measurements from different request storage sources.
    class Redis
      ActionCable = Class.new(RedisBase)
      Cache = Class.new(RedisBase)
      Queues = Class.new(RedisBase)
      SharedState = Class.new(RedisBase)

      STORAGES = [ActionCable, Cache, Queues, SharedState].freeze

      # Milliseconds represented in seconds (from 1 to 500 milliseconds).
      QUERY_TIME_BUCKETS = [0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5].freeze

      class << self
        def detail_store
          STORAGES.flat_map(&:detail_store)
        end

        %i[get_request_count query_time read_bytes write_bytes].each do |method|
          define_method method do
            STORAGES.sum(&method) # rubocop:disable CodeReuse/ActiveRecord
          end
        end
      end
    end
  end
end
