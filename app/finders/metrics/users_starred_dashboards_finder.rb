# frozen_string_literal: true

module Metrics
  class UsersStarredDashboardsFinder
    def initialize(user:, project:, params: {})
      @user = user
      @project = project
      @params = params
    end

    def execute
      return ::Metrics::UsersStarredDashboard.none unless Ability.allowed?(user, :read_metrics_user_starred_dashboard, project)

      items = starred_dashboards
      items = by_project(items)
      by_dashboard(items)
    end

    private

    attr_reader :user, :project, :params

    def by_project(items)
      items.for_project(project)
    end

    def by_dashboard(items)
      return items unless params[:dashboard_path]

      items.merge(starred_dashboards.for_project_dashboard(project, params[:dashboard_path]))
    end

    def starred_dashboards
      @starred_dashboards ||= user.metrics_users_starred_dashboards
    end
  end
end
