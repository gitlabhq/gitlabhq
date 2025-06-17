# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: UniqueTotalsMetric
        # event:
        #   name: gitlab_cli_command_used
        #   unique: label
        #   operator: 'total'
        #
        class UniqueTotalsMetric < BaseMetric
          include Gitlab::UsageDataCounters::RedisHashCounter

          def value
            metric_definition.event_selection_rules.to_h do |rule|
              keys = rule.redis_keys_for_time_frame(time_frame)

              values = keys.each_with_object({}) do |key, totals|
                values_for_key = redis_usage_data { get_hash(key) }

                totals.merge!(values_for_key) { |_, value_1, value_2| value_1 + value_2 }
              end

              [rule.unique_identifier_name.to_s, values]
            end
          end
        end
      end
    end
  end
end
