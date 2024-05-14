# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        AggregatedMetricError = Class.new(StandardError)
        UnknownAggregationSource = Class.new(AggregatedMetricError)
        DisallowedAggregationTimeFrame = Class.new(AggregatedMetricError)
        UndefinedEvents = Class.new(AggregatedMetricError)

        DATABASE_SOURCE = 'database'
        REDIS_SOURCE = 'redis_hll'
        INTERNAL_EVENTS_SOURCE = 'internal_events'

        SOURCES = {
          DATABASE_SOURCE => Sources::PostgresHll,
          REDIS_SOURCE => Sources::RedisHll,
          # Same strategy as RedisHLL, since they are a part of internal events
          # and should get counted together with other RedisHLL-based aggregations
          INTERNAL_EVENTS_SOURCE => Sources::RedisHll
        }.freeze
      end
    end
  end
end
