# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class PrometheusEnabledMetric < GenericMetric
          value do
            Gitlab::Prometheus::Internal.prometheus_enabled?
          end
        end
      end
    end
  end
end
