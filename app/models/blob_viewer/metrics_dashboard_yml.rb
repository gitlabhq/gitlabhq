# frozen_string_literal: true

module BlobViewer
  class MetricsDashboardYml < Base
    include ServerSide
    include Gitlab::Utils::StrongMemoize
    include Auxiliary

    self.partial_name = 'metrics_dashboard_yml'
    self.loading_partial_name = 'metrics_dashboard_yml_loading'
    self.file_types = %i(metrics_dashboard)
    self.binary = false

    def self.can_render?(blob, verify_binary: true)
      super && !Feature.enabled?(:remove_monitor_metrics)
    end

    def valid?
      errors.blank?
    end

    def errors
      strong_memoize(:errors) do
        prepare!
        parse_blob_data
      end
    end

    private

    def parse_blob_data
      old_metrics_dashboard_validation
    end

    def old_metrics_dashboard_validation
      yaml = ::Gitlab::Config::Loader::Yaml.new(blob.data).load_raw!
      ::PerformanceMonitoring::PrometheusDashboard.from_json(yaml)
      []
    rescue Gitlab::Config::Loader::FormatError => e
      ["YAML syntax: #{e.message}"]
    rescue ActiveModel::ValidationError => e
      e.model.errors.messages.map { |messages| messages.join(': ') }
    end
  end
end
