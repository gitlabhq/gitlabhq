# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: RedisMetric
        # options:
        #   event: pushes
        #   counter_class: SourceCodeCounter
        #
        class RedisMetric < BaseMetric
          def initialize(time_frame:, options: {})
            super

            raise ArgumentError, "'event' option is required" unless metric_event.present?
            raise ArgumentError, "'counter class' option is required" unless counter_class.present?
          end

          def metric_event
            options[:event]
          end

          def counter_class_name
            options[:counter_class]
          end

          def counter_class
            "Gitlab::UsageDataCounters::#{counter_class_name}".constantize
          end

          def value
            redis_usage_data do
              counter_class.read(metric_event)
            end
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(:redis)
          end
        end
      end
    end
  end
end
