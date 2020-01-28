# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusMetric
    include ActiveModel::Model

    attr_accessor :id, :unit, :label, :query, :query_range

    validates :unit, presence: true
    validates :query, presence: true, unless: :query_range
    validates :query_range, presence: true, unless: :query

    def self.from_json(json_content)
      metric = PrometheusMetric.new(
        id: json_content['id'],
        unit: json_content['unit'],
        label: json_content['label'],
        query: json_content['query'],
        query_range: json_content['query_range']
      )

      metric.tap(&:validate!)
    end
  end
end
