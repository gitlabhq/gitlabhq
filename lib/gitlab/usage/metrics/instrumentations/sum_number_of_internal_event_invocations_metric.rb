# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SumNumberOfInternalEventInvocationsMetric < GenericMetric
          include Gitlab::UsageDataCounters::RedisCounter

          def value
            all_internal_event_keys.sum do |key|
              redis_usage_data do
                total_count(key)
              end
            end
          end

          private

          def all_internal_event_keys
            internal_event_definitions = Gitlab::Tracking::EventDefinition.definitions.select(&:internal_events?)

            internal_event_definitions.flat_map do |event_definition|
              keys_for_event_definition(event_definition)
            end
          end

          def keys_for_event_definition(event_definition)
            event_selection_rule = EventSelectionRule.new(name: event_definition.action, time_framed: true)

            event_selection_rule.redis_keys_for_time_frame(time_frame)
          end
        end
      end
    end
  end
end
