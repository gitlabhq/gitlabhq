# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitalyApdexMetric < PrometheusMetric
          value do |client|
            result = client.query('avg_over_time(gitlab_usage_ping:gitaly_apdex:ratio_avg_over_time_5m[1w])').first

            break FALLBACK unless result

            result['value'].last.to_f
          end
        end
      end
    end
  end
end
