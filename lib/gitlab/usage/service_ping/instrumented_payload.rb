# frozen_string_literal: true

# Service Ping payload build using the instrumentation classes
# for given metrics key_paths and output method
module Gitlab
  module Usage
    module ServicePing
      class InstrumentedPayload
        attr_reader :metrics_key_paths
        attr_reader :output_method

        def initialize(metrics_key_paths, output_method)
          @metrics_key_paths = metrics_key_paths
          @output_method = output_method
        end

        def build
          metrics_key_paths.map do |key_path|
            compute_instrumental_value(key_path, output_method)
          end.reduce({}, :deep_merge)
        end

        private

        # Not all metrics definitions have instrumentation classes
        # The value can be computed only for those that have it
        def instrumented_metrics_defintions
          Gitlab::Usage::MetricDefinition.with_instrumentation_class
        end

        def compute_instrumental_value(key_path, output_method)
          definition = instrumented_metrics_defintions.find { |df| df.key_path == key_path }

          return {} unless definition.present?

          Gitlab::Usage::Metric.new(definition).method(output_method).call
        rescue StandardError => error
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
          metric_fallback(key_path)
        end

        def metric_fallback(key_path)
          ::Gitlab::Usage::Metrics::KeyPathProcessor.process(key_path, ::Gitlab::Utils::UsageData::FALLBACK)
        end
      end
    end
  end
end
