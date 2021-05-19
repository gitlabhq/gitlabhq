# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class RedisHLLMetric < BaseMetric
          # Usage example
          #
          # class CountUsersVisitingAnalyticsValuestreamMetric < RedisHLLMetric
          #   event_names :g_analytics_valuestream
          # end
          class << self
            def event_names(events = nil)
              @metric_events = events
            end

            attr_reader :metric_events
          end

          def value
            redis_usage_data do
              event_params = time_constraints.merge(event_names: self.class.metric_events)

              Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**event_params)
            end
          end

          private

          def time_constraints
            case time_frame
            when '28d'
              { start_date: 4.weeks.ago.to_date, end_date: Date.current }
            when '7d'
              { start_date: 7.days.ago.to_date, end_date: Date.current }
            else
              raise "Unknown time frame: #{time_frame} for TimeConstraint"
            end
          end
        end
      end
    end
  end
end
