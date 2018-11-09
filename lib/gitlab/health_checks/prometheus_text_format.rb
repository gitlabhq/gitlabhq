# frozen_string_literal: true

module Gitlab
  module HealthChecks
    class PrometheusTextFormat
      def marshal(metrics)
        "#{metrics_with_type_declarations(metrics).join("\n")}\n"
      end

      private

      def metrics_with_type_declarations(metrics)
        type_declaration_added = {}

        metrics.flat_map do |metric|
          metric_lines = []

          unless type_declaration_added.key?(metric.name)
            type_declaration_added[metric.name] = true
            metric_lines << metric_type_declaration(metric)
          end

          metric_lines << metric_text(metric)
        end
      end

      def metric_type_declaration(metric)
        "# TYPE #{metric.name} gauge"
      end

      def metric_text(metric)
        labels = metric.labels&.map { |key, value| "#{key}=\"#{value}\"" }&.join(',') || ''

        if labels.empty?
          "#{metric.name} #{metric.value}"
        else
          "#{metric.name}{#{labels}} #{metric.value}"
        end
      end
    end
  end
end
