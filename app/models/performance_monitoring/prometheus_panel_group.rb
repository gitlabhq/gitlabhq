# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusPanelGroup
    include ActiveModel::Model

    attr_accessor :group, :priority, :panels

    validates :group, presence: true
    validates :panels, presence: true
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
          panels: attributes['panels']&.map { |panel| PrometheusPanel.from_json(panel) }
        )
      end
    end
  end
end
