# frozen_string_literal: true

# Updates the content of a specified dashboard in .yml file inside `.gitlab/dashboards`
module Metrics
  module Dashboard
    class UpdateDashboardService < ::BaseService
      include Stepable

      ALLOWED_FILE_TYPE = '.yml'
      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT

      steps :check_push_authorized,
        :check_branch_name,
        :check_file_type,
        :update_file

      def execute
        execute_steps
      end

      private

      def check_push_authorized(result)
        return error(_('You are not allowed to push into this branch. Create another branch or open a merge request.'), :forbidden) unless push_authorized?

        success(result)
      end

      def check_branch_name(result)
        return error(_('There was an error updating the dashboard, branch name is invalid.'), :bad_request) unless valid_branch_name?
        return error(_('There was an error updating the dashboard, branch named: %{branch} already exists.') % { branch: params[:branch] }, :bad_request) unless new_or_default_branch?

        success(result)
      end

      def check_file_type(result)
        return error(_('The file name should have a .yml extension'), :bad_request) unless target_file_type_valid?

        success(result)
      end

      def update_file(result)
        file_update_response = ::Files::UpdateService.new(project, current_user, dashboard_attrs).execute

        if file_update_response[:status] == :success
          success(result.merge(file_update_response, http_status: :created, dashboard: dashboard_details))
        else
          error(file_update_response[:message], :bad_request)
        end
      end

      def push_authorized?
        Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(branch)
      end

      def valid_branch_name?
        Gitlab::GitRefValidator.validate(branch)
      end

      def new_or_default_branch?
        !repository.branch_exists?(branch) || project.default_branch == branch
      end

      def target_file_type_valid?
        File.extname(params[:file_name]) == ALLOWED_FILE_TYPE
      end

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

      def update_dashboard_path
        File.join(USER_DASHBOARDS_DIR, file_name)
      end

      def file_name
        @file_name ||= File.basename(CGI.unescape(params[:file_name]))
      end

      def branch
        @branch ||= params[:branch]
      end

      def update_dashboard_content
        ::PerformanceMonitoring::PrometheusDashboard.from_json(params[:file_content]).to_yaml
      end

      def repository
        @repository ||= project.repository
      end

      def dashboard_details
        {
          path: update_dashboard_path,
          display_name: ::Metrics::Dashboard::ProjectDashboardService.name_for_path(update_dashboard_path),
          default: false,
          system_dashboard: false
        }
      end
    end
  end
end
