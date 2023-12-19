# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class PrometheusMetric < GenericMetric
          # Usage example
          #
          # class GitalyApdexMetric < PrometheusMetric
          #   value do
          #     result = client.query('avg_over_time(gitlab_usage_ping:gitaly_apdex:ratio_avg_over_time_5m[1w])').first
          #
          #     break FALLBACK unless result
          #
          #     result['value'].last.to_f
          #   end
          # end
          def value
            with_prometheus_client(verify: false, fallback: FALLBACK) do |client|
              self.class.metric_value.call(client)
            end
          end
        end
      end
    end
  end
end
