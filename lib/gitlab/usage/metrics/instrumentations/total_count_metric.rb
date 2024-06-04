# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: TotalCountMetric
        # options:
        #   event: commit_pushed
        #
        class TotalCountMetric < BaseMetric
          include Gitlab::UsageDataCounters::RedisCounter

          def value
            keys = metric_definition.event_selection_rules.flat_map { |e| e.redis_keys_for_time_frame(time_frame) }

            keys.sum do |key|
              redis_usage_data do
                total_count(key)
              end
            end
          end
        end
      end
    end
  end
end
