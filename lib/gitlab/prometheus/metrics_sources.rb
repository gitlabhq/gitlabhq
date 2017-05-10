module Gitlab::Prometheus
  module MetricsSources
    def self.additional_metrics
      @additional_metrics ||= YAML.load_file(Rails.root.join('config/additional_metrics.yml')).deep_symbolize_keys.freeze
    end
  end
end
