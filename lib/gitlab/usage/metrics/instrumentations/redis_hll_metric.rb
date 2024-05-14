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
          def initialize(metric_definition)
            super

            raise ArgumentError, "options events are required" unless event_names.present?
          end

          def value
            redis_usage_data do
              event_params = time_constraints.merge(event_names: event_names, property_name: property_name)

              Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**event_params)
            end
          end

          private

          def event_names
            # use `events:` attribute instead of `options:` attribute when possible
            return options[:events] if events.empty?

            events.pluck(:name)
          end

          def property_name
            return if events.empty?

            uniques = events.pluck(:unique).uniq

            return uniques.first if uniques.count == 1

            message = "RedisHLLMetric for events #{events}, options #{options} has multiple unique_by values"
            raise Gitlab::Usage::MetricDefinition::InvalidError, message
          end

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
