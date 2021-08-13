# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        UNION_OF_AGGREGATED_METRICS = 'OR'
        INTERSECTION_OF_AGGREGATED_METRICS = 'AND'
        ALLOWED_METRICS_AGGREGATIONS = [UNION_OF_AGGREGATED_METRICS, INTERSECTION_OF_AGGREGATED_METRICS].freeze
        AGGREGATED_METRICS_PATH = Rails.root.join('config/metrics/aggregates/*.yml')
        AggregatedMetricError = Class.new(StandardError)
        UnknownAggregationOperator = Class.new(AggregatedMetricError)
        UnknownAggregationSource = Class.new(AggregatedMetricError)
        DisallowedAggregationTimeFrame = Class.new(AggregatedMetricError)

        DATABASE_SOURCE = 'database'
        REDIS_SOURCE = 'redis'

        SOURCES = {
          DATABASE_SOURCE => Sources::PostgresHll,
          REDIS_SOURCE => Sources::RedisHll
        }.freeze
      end
    end
  end
end
