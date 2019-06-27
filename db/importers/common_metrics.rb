require_relative './common_metrics/importer'
require_relative './common_metrics/prometheus_metric'
require_relative './common_metrics/prometheus_metric_enums'

require Rails.root.join('ee', 'db', 'importers', 'common_metrics') if Gitlab.ee?

module Importers
  module CommonMetrics
  end

  # Patch to preserve old CommonMetricsImporter api
  module CommonMetricsImporter
    def self.new(*args)
      Importers::CommonMetrics::Importer.new(*args)
    end
  end
end
