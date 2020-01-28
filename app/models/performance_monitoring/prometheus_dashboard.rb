# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusDashboard
    include ActiveModel::Model

    attr_accessor :dashboard, :panel_groups

    validates :dashboard, presence: true
    validates :panel_groups, presence: true

    def self.from_json(json_content)
      dashboard = new(
        dashboard: json_content['dashboard'],
        panel_groups: json_content['panel_groups'].map { |group| PrometheusPanelGroup.from_json(group) }
      )

      dashboard.tap(&:validate!)
    end

    def to_yaml
      self.as_json(only: valid_attributes).to_yaml
    end

    private

    def valid_attributes
      %w(panel_groups panels metrics group priority type title y_label weight id unit label query query_range dashboard)
    end
  end
end
