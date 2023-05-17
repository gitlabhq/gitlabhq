# frozen_string_literal: true

module Projects
  module PerformanceMonitoring
    class DashboardsController < ::Projects::ApplicationController
      include BlobHelper

      before_action :check_repository_available!
      before_action :validate_required_params!

      rescue_from ActionController::ParameterMissing do |exception|
        respond_error(http_status: :bad_request, message: _('Request parameter %{param} is missing.') % { param: exception.param })
      end

      feature_category :metrics
      urgency :low

      def create
        return not_found if Feature.enabled?(:remove_monitor_metrics)

        result = ::Metrics::Dashboard::CloneDashboardService.new(project, current_user, dashboard_params).execute

        if result[:status] == :success
          respond_success(result)
        else
          respond_error(result)
        end
      end

      def update
        return not_found if Feature.enabled?(:remove_monitor_metrics)

        result = ::Metrics::Dashboard::UpdateDashboardService.new(project, current_user, dashboard_params.merge(file_content_params)).execute

        if result[:status] == :success
          respond_update_success(result)
        else
          respond_error(result)
        end
      end

      private

      def respond_success(result)
        set_web_ide_link_notice(result.dig(:dashboard, :path))
        respond_to do |format|
          format.json { render status: result.delete(:http_status), json: result }
        end
      end

      def respond_error(result)
        respond_to do |format|
          format.json { render json: { error: result[:message] }, status: result[:http_status] }
        end
      end

      def set_web_ide_link_notice(new_dashboard_path)
        web_ide_link_start = "<a href=\"#{ide_edit_path(project, redirect_safe_branch_name, new_dashboard_path)}\">"
        message = _("Your dashboard has been copied. You can %{web_ide_link_start}edit it here%{web_ide_link_end}.") % { web_ide_link_start: web_ide_link_start, web_ide_link_end: "</a>" }
        flash[:notice] = message.html_safe
      end

      def respond_update_success(result)
        set_web_ide_link_update_notice(result.dig(:dashboard, :path))
        respond_to do |format|
          format.json { render status: result.delete(:http_status), json: result }
        end
      end

      def set_web_ide_link_update_notice(new_dashboard_path)
        web_ide_link_start = "<a href=\"#{ide_edit_path(project, redirect_safe_branch_name, new_dashboard_path)}\">"
        message = _("Your dashboard has been updated. You can %{web_ide_link_start}edit it here%{web_ide_link_end}.") % { web_ide_link_start: web_ide_link_start, web_ide_link_end: "</a>" }
        flash[:notice] = message.html_safe
      end

      def validate_required_params!
        params.require(%i[branch file_name dashboard commit_message])
      end

      def redirect_safe_branch_name
        repository.find_branch(params[:branch]).name
      end

      def dashboard_params
        params.permit(%i[branch file_name dashboard commit_message]).to_h
      end

      def file_content_params
        params.permit(
          file_content: [
            :dashboard,
            panel_groups: [
              :group,
              :priority,
              panels: [
                :type,
                :title,
                :y_label,
                :weight,
                metrics: [
                  :id,
                  :unit,
                  :label,
                  :query,
                  :query_range
                ]
              ]
            ]
          ]
        )
      end
    end
  end
end
