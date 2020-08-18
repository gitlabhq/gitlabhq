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
      yaml = ::Gitlab::Config::Loader::Yaml.new(blob.data).load_raw!
      Gitlab::Metrics::Dashboard::Validator
        .errors(yaml, dashboard_path: blob.path, project: project)
    rescue Gitlab::Config::Loader::FormatError => error
      [error]
    end
  end
end
