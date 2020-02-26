# frozen_string_literal: true

# Updates the content of a specified dashboard in .yml file inside `.gitlab/dashboards`
module Metrics
  module Dashboard
    class UpdateDashboardService < ::BaseService
      ALLOWED_FILE_TYPE = '.yml'
      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT

      def execute
        catch(:error) do
          throw(:error, error(_(%q(You can't commit to this project)), :forbidden)) unless push_authorized?

          result = ::Files::UpdateService.new(project, current_user, dashboard_attrs).execute
          throw(:error, result.merge(http_status: :bad_request)) unless result[:status] == :success

          success(result.merge(http_status: :created, dashboard: dashboard_details))
        end
      end

      private

      def dashboard_attrs
        {
          commit_message: params[:commit_message],
          file_path: update_dashboard_path,
          file_content: update_dashboard_content,
          encoding: 'text',
          branch_name: branch,
          start_branch: repository.branch_exists?(branch) ? branch : project.default_branch
        }
      end

      def dashboard_details
        {
          path: update_dashboard_path,
          display_name: ::Metrics::Dashboard::ProjectDashboardService.name_for_path(update_dashboard_path),
          default: false,
          system_dashboard: false
        }
      end

      def push_authorized?
        Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(branch)
      end

      def branch
        @branch ||= begin
          throw(:error, error(_('There was an error updating the dashboard, branch name is invalid.'), :bad_request)) unless valid_branch_name?
          throw(:error, error(_('There was an error updating the dashboard, branch named: %{branch} already exists.') % { branch: params[:branch] }, :bad_request)) unless new_or_default_branch?

          params[:branch]
        end
      end

      def new_or_default_branch?
        !repository.branch_exists?(params[:branch]) || project.default_branch == params[:branch]
      end

      def valid_branch_name?
        Gitlab::GitRefValidator.validate(params[:branch])
      end

      def update_dashboard_path
        File.join(USER_DASHBOARDS_DIR, file_name)
      end

      def target_file_type_valid?
        File.extname(params[:file_name]) == ALLOWED_FILE_TYPE
      end

      def file_name
        @file_name ||= begin
          throw(:error, error(_('The file name should have a .yml extension'), :bad_request)) unless target_file_type_valid?

          File.basename(CGI.unescape(params[:file_name]))
        end
      end

      def update_dashboard_content
        ::PerformanceMonitoring::PrometheusDashboard.from_json(params[:file_content]).to_yaml
      end

      def repository
        @repository ||= project.repository
      end
    end
  end
end
