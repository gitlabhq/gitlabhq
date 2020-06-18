# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusMetric
    include ActiveModel::Model

    attr_accessor :id, :unit, :label, :query, :query_range

    validates :unit, presence: true
    validates :query, presence: true, unless: :query_range
    validates :query_range, presence: true, unless: :query

    class << self
      def from_json(json_content)
        build_from_hash(json_content).tap(&:validate!)
      end

      private

      def build_from_hash(attributes)
        return new unless attributes.is_a?(Hash)

        new(
          id: attributes['id'],
          unit: attributes['unit'],
          label: attributes['label'],
          query: attributes['query'],
          query_range: attributes['query_range']
        )
      end
    end
  end
end
