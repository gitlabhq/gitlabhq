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

        SOURCES = {
          DATABASE_SOURCE => Sources::PostgresHll
        }.freeze
      end
    end
  end
end
