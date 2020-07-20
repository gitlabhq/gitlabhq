# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusPanelGroup
    include ActiveModel::Model

    attr_accessor :group, :priority, :panels

    validates :group, presence: true
    validates :panels, array_members: { member_class: PerformanceMonitoring::PrometheusPanel }

    class << self
      def from_json(json_content)
        build_from_hash(json_content).tap(&:validate!)
      end

      private

      def build_from_hash(attributes)
        return new unless attributes.is_a?(Hash)

        new(
          group: attributes['group'],
          priority: attributes['priority'],
          panels: initialize_children_collection(attributes['panels'])
        )
      end

      def initialize_children_collection(children)
        return unless children.is_a?(Array)

        children.map { |panels| PerformanceMonitoring::PrometheusPanel.from_json(panels) }
      end
    end
  end
end
