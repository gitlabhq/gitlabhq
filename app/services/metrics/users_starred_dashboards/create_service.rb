# frozen_string_literal: true

# Create Metrics::UsersStarredDashboard entry for given user based on matched dashboard_path, project
module Metrics
  module UsersStarredDashboards
    class CreateService < ::BaseService
      include Stepable

      steps :authorize_create_action,
            :parse_dashboard_path,
            :create

      def initialize(user, project, dashboard_path)
        @user = user
        @project = project
        @dashboard_path = dashboard_path
      end

      def execute
        keys = %i[status message starred_dashboard]
        status, message, dashboards = execute_steps.values_at(*keys)

        if status != :success
          ServiceResponse.error(message: message)
        else
          ServiceResponse.success(payload: dashboards)
        end
      end

      private

      attr_reader :user, :project, :dashboard_path

      def authorize_create_action(_options)
        if Ability.allowed?(user, :create_metrics_user_starred_dashboard, project)
          success(user: user, project: project)
        else
          error(s_('Metrics::UsersStarredDashboards|You are not authorized to add star to this dashboard'))
        end
      end

      def parse_dashboard_path(options)
        if dashboard_path_exists?
          options[:dashboard_path] = dashboard_path
          success(options)
        else
          error(s_('Metrics::UsersStarredDashboards|Dashboard with requested path can not be found'))
        end
      end

      def create(options)
        starred_dashboard = build_starred_dashboard_from(options)

        if starred_dashboard.save
          success(starred_dashboard: starred_dashboard)
        else
          error(starred_dashboard.errors.messages)
        end
      end

      def build_starred_dashboard_from(options)
        Metrics::UsersStarredDashboard.new(
          user: options.fetch(:user),
          project: options.fetch(:project),
          dashboard_path: options.fetch(:dashboard_path)
        )
      end

      def dashboard_path_exists?
        Gitlab::Metrics::Dashboard::Finder
          .find_all_paths(project)
          .any? { |dashboard| dashboard[:path] == dashboard_path }
      end
    end
  end
end
