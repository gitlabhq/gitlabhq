# frozen_string_literal: true

module Gitlab
  class UsageDataMetrics
    class << self
      # Build the Usage Ping JSON payload from metrics YAML definitions which have instrumentation class set
      def uncached_data
        ::Gitlab::Usage::MetricDefinition.all.map do |definition|
          instrumentation_class = definition.attributes[:instrumentation_class]
          options = definition.attributes[:options]

          if instrumentation_class.present?
            metric_value = "Gitlab::Usage::Metrics::Instrumentations::#{instrumentation_class}".constantize.new(
              time_frame: definition.attributes[:time_frame],
              options: options).value

            metric_payload(definition.key_path, metric_value)
          else
            {}
          end
        end.reduce({}, :deep_merge)
      end

      private

      def metric_payload(key_path, value)
        ::Gitlab::Usage::Metrics::KeyPathProcessor.process(key_path, value)
      end
    end
  end
end
