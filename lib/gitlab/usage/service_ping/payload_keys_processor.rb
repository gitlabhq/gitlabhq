# frozen_string_literal: true

# Process the UsageData payload to get the keys that have a metric defintion
# Get the missing keys from the payload
module Gitlab
  module Usage
    module ServicePing
      class PayloadKeysProcessor
        attr_reader :old_payload

        def initialize(old_payload)
          @old_payload = old_payload
        end

        def key_paths
          @key_paths ||= payload_keys.to_a.flatten.compact
        end

        def missing_instrumented_metrics_key_paths
          @missing_key_paths ||= metrics_with_instrumentation.map(&:key) - key_paths
        end

        private

        def payload_keys(payload = old_payload, parents = [])
          return unless payload.is_a?(Hash)

          payload.map do |key, value|
            if has_metric_definition?(key, parents)
              parents.dup.append(key).join('.')
            elsif value.is_a?(Hash)
              payload_keys(value, parents.dup << key)
            end
          end
        end

        def has_metric_definition?(key, parent_keys)
          key_path = parent_keys.dup.append(key).join('.')
          metric_definitions.key?(key_path)
        end

        def metric_definitions
          ::Gitlab::Usage::MetricDefinition.not_removed
        end

        def metrics_with_instrumentation
          ::Gitlab::Usage::MetricDefinition.with_instrumentation_class
        end
      end
    end
  end
end

Gitlab::Usage::ServicePing::PayloadKeysProcessor.prepend_mod_with('Gitlab::Usage::ServicePing::PayloadKeysProcessor')
