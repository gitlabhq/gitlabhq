# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusPanelGroup
    include ActiveModel::Model

    attr_accessor :group, :priority, :panels

    validates :group, presence: true
    validates :panels, presence: true

    def self.from_json(json_content)
      panel_group = new(
        group: json_content['group'],
        priority: json_content['priority'],
        panels: json_content['panels']&.map { |panel| PrometheusPanel.from_json(panel) }
      )

      panel_group.tap(&:validate!)
    end
  end
end
