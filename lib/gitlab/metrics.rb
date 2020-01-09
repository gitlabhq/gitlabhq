# frozen_string_literal: true

module Gitlab
  module Metrics
    include Gitlab::Metrics::InfluxDb
    include Gitlab::Metrics::Prometheus

    @error = false

    def self.enabled?
      influx_metrics_enabled? || prometheus_metrics_enabled?
    end

    def self.error?
      @error
    end
  end
end
