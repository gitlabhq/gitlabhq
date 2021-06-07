# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class RedisHLLMetric < BaseMetric
          # Usage example
          #
          # In metric YAML defintion
          # instrumentation_class: RedisHLLMetric
          #   events:
          #     - g_analytics_valuestream
          # end
          class << self
            attr_reader :metric_operation
            @metric_operation = :redis
          end

          def initialize(time_frame:, options: {})
            super

            raise ArgumentError, "options events are required" unless metric_events.present?
          end

          def metric_events
            options[:events]
          end

          def value
            redis_usage_data do
              event_params = time_constraints.merge(event_names: metric_events)

              Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**event_params)
            end
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(
              self.class.metric_operation
            )
          end

          private

          def time_constraints
            case time_frame
            when '28d'
              monthly_time_range
            when '7d'
              weekly_time_range
            else
              raise "Unknown time frame: #{time_frame} for RedisHLLMetric"
            end
          end
        end
      end
    end
  end
end
