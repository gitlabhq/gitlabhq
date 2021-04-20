# frozen_string_literal: true

# Delete all matching Metrics::UsersStarredDashboard entries for given user based on matched dashboard_path, project
module Metrics
  module UsersStarredDashboards
    class DeleteService < ::BaseService
      def initialize(user, project, dashboard_path = nil)
        @user = user
        @project = project
        @dashboard_path = dashboard_path
      end

      def execute
        ServiceResponse.success(payload: { deleted_rows: starred_dashboards.delete_all })
      end

      private

      attr_reader :user, :project, :dashboard_path

      def starred_dashboards
        # since deleted records are scoped to their owner there is no need to
        # check if that user can delete them, also if user lost access to
        # project it shouldn't block that user from removing them
        dashboards = user.metrics_users_starred_dashboards

        if dashboard_path.present?
          dashboards.for_project_dashboard(project, dashboard_path)
        else
          dashboards.for_project(project)
        end
      end
    end
  end
end
