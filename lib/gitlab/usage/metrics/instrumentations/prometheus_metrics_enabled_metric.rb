# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class PrometheusMetricsEnabledMetric < GenericMetric
          value do
            Gitlab::Metrics.prometheus_metrics_enabled?
          end
        end
      end
    end
  end
end
