# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: TotalSumMetric
        # options:
        #   event: commit_pushed
        #   operation: sum(value)
        #
        class TotalSumMetric < BaseMetric
          include Gitlab::UsageDataCounters::RedisSum

          def value
            keys = metric_definition.event_selection_rules.flat_map { |e| e.redis_keys_for_time_frame(time_frame) }
            keys.sum do |key|
              redis_usage_data do
                get(key)
              end
            end
          end
        end
      end
    end
  end
end
