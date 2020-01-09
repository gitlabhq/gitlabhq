# frozen_string_literal: true

module Projects
  module PerformanceMonitoring
    class DashboardsController < ::Projects::ApplicationController
      include BlobHelper

      before_action :check_repository_available!
      before_action :validate_required_params!
      before_action :validate_dashboard_template!
      before_action :authorize_push!

      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT
      DASHBOARD_TEMPLATES = {
        ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH
      }.freeze

      def create
        result = ::Files::CreateService.new(project, current_user, dashboard_attrs).execute

        if result[:status] == :success
          respond_success
        else
          respond_error(result[:message])
        end
      end

      private

      def respond_success
        respond_to do |format|
          format.html { redirect_to ide_edit_path(project, redirect_safe_branch_name, new_dashboard_path) }
          format.json { render json: { redirect_to: ide_edit_path(project, redirect_safe_branch_name, new_dashboard_path) }, status: :created }
        end
      end

      def respond_error(message)
        flash[:alert] = message

        respond_to do |format|
          format.html { redirect_back_or_default(default: namespace_project_environments_path) }
          format.json { render json: { error: message }, status: :bad_request }
        end
      end

      def authorize_push!
        access_denied!(%q(You can't commit to this project)) unless user_access(project).can_push_to_branch?(params[:branch])
      end

      def validate_required_params!
        params.require(%i(branch file_name dashboard))
      end

      def validate_dashboard_template!
        access_denied! unless dashboard_template
      end

      def dashboard_attrs
        {
          commit_message: commit_message,
          file_path: new_dashboard_path,
          file_content: new_dashboard_content,
          encoding: 'text',
          branch_name: params[:branch],
          start_branch: repository.branch_exists?(params[:branch]) ? params[:branch] : project.default_branch
        }
      end

      def commit_message
        params[:commit_message] || "Create custom dashboard #{params[:file_name]}"
      end

      def new_dashboard_path
        File.join(USER_DASHBOARDS_DIR, params[:file_name])
      end

      def new_dashboard_content
        File.read(Rails.root.join(dashboard_template))
      end

      def dashboard_template
        dashboard_templates[params[:dashboard]]
      end

      def dashboard_templates
        DASHBOARD_TEMPLATES
      end

      def redirect_safe_branch_name
        repository.find_branch(params[:branch]).name
      end
    end
  end
end

Projects::PerformanceMonitoring::DashboardsController.prepend_if_ee('EE::Projects::PerformanceMonitoring::DashboardsController')
