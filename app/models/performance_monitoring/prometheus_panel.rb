# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusPanel
    include ActiveModel::Model

    attr_accessor :type, :title, :y_label, :weight, :metrics, :y_axis, :max_value

    validates :title, presence: true
    validates :metrics, array_members: { member_class: PerformanceMonitoring::PrometheusMetric }

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
          metrics: initialize_children_collection(attributes['metrics'])
        )
      end

      def initialize_children_collection(children)
        return unless children.is_a?(Array)

        children.map { |metrics| PerformanceMonitoring::PrometheusMetric.from_json(metrics) }
      end
    end

    def id(group_title)
      Digest::SHA2.hexdigest([group_title, type, title].join)
    end
  end
end
