module Gitlab
  module Metrics
    include Gitlab::Metrics::InfluxDb
    include Gitlab::Metrics::Prometheus

    def self.enabled?
      influx_metrics_enabled? || prometheus_metrics_enabled?
    end
  end
end
