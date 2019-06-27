module Importers
  module CommonMetrics
    class PrometheusMetric < ActiveRecord::Base
      enum group: PrometheusMetricEnums.groups
      scope :common, -> { where(common: true) }
    end
  end
end
