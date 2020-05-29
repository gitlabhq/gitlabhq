# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusDashboard
    include ActiveModel::Model

    attr_accessor :dashboard, :panel_groups, :path, :environment, :priority, :templating, :links

    validates :dashboard, presence: true
    validates :panel_groups, presence: true

    class << self
      def from_json(json_content)
        dashboard = new(
          dashboard: json_content['dashboard'],
          panel_groups: json_content['panel_groups'].map { |group| PrometheusPanelGroup.from_json(group) }
        )

        dashboard.tap(&:validate!)
      end

      def find_for(project:, user:, path:, options: {})
        dashboard_response = Gitlab::Metrics::Dashboard::Finder.find(project, user, options.merge(dashboard_path: path))
        return unless dashboard_response[:status] == :success

        new(
          {
            path: path,
            environment: options[:environment]
          }.merge(dashboard_response[:dashboard])
        )
      end
    end

    def to_yaml
      self.as_json(only: yaml_valid_attributes).to_yaml
    end

    private

    def yaml_valid_attributes
      %w(panel_groups panels metrics group priority type title y_label weight id unit label query query_range dashboard)
    end
  end
end
