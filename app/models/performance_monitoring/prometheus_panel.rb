# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusPanel
    include ActiveModel::Model

    attr_accessor :type, :title, :y_label, :weight, :metrics, :y_axis, :max_value

    validates :title, presence: true
    validates :metrics, presence: true
    class << self
      def from_json(json_content)
        build_from_hash(json_content).tap(&:validate!)
      end

      private

      def build_from_hash(attributes)
        return new unless attributes.is_a?(Hash)

        new(
          type: attributes['type'],
          title: attributes['title'],
          y_label: attributes['y_label'],
          weight: attributes['weight'],
          metrics: attributes['metrics']&.map { |metric| PrometheusMetric.from_json(metric) }
        )
      end
    end

    def id(group_title)
      Digest::SHA2.hexdigest([group_title, type, title].join)
    end
  end
end
