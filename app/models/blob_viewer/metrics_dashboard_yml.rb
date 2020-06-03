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
      ::PerformanceMonitoring::PrometheusDashboard.from_json(YAML.safe_load(blob.data))
      nil
    rescue Psych::SyntaxError => error
      wrap_yml_syntax_error(error)
    rescue ActiveModel::ValidationError => invalid
      invalid.model.errors
    end

    def wrap_yml_syntax_error(error)
      ::PerformanceMonitoring::PrometheusDashboard.new.errors.tap do |errors|
        errors.add(:'YAML syntax', error.message)
      end
    end
  end
end
