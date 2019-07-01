# This functionality has been moved to the lib/gitlab/importers/common_metrics module.
# This is here only to preserve existing ::Importers::CommonMetricsImporter api
module Importers
  module CommonMetricsImporter
    def self.new(*args)
      Gitlab::Importers::CommonMetrics::Importer.new(*args)
    end
  end
end
