module Gitlab
  module Metrics
    extend Gitlab::Metrics::InfluxDb
    extend Gitlab::Metrics::Prometheus

    def self.enabled?
      influx_metrics_enabled? || prometheus_metrics_enabled?
    end
  end
end
