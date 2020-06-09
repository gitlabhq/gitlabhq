# frozen_string_literal: true

module Projects
  module Settings
    class OperationsController < Projects::ApplicationController
      before_action :authorize_admin_operations!
      before_action :authorize_read_prometheus_alerts!, only: [:reset_alerting_token]

      respond_to :json, only: [:reset_alerting_token]

      helper_method :error_tracking_setting

      def show
        render locals: { prometheus_service: prometheus_service }
      end

      def update
        result = ::Projects::Operations::UpdateService.new(project, current_user, update_params).execute

        track_events(result)
        render_update_response(result)
      end

      # overridden in EE
      def track_events(result)
        if result[:status] == :success
          ::Gitlab::Tracking::IncidentManagement.track_from_params(
            update_params[:incident_management_setting_attributes]
          )
        end
      end

      def reset_alerting_token
        result = ::Projects::Operations::UpdateService
          .new(project, current_user, alerting_params)
          .execute

        if result[:status] == :success
          render json: { token: project.alerting_setting.token }
        else
          render json: {}, status: :unprocessable_entity
        end
      end

      private

      def alerting_params
        { alerting_setting_attributes: { regenerate_token: true } }
      end

      def prometheus_service
        project.find_or_initialize_service(::PrometheusService.to_param)
      end

      def render_update_response(result)
        respond_to do |format|
          format.html do
            render_update_html_response(result)
          end

          format.json do
            render_update_json_response(result)
          end
        end
      end

      def render_update_html_response(result)
        if result[:status] == :success
          flash[:notice] = _('Your changes have been saved')
          redirect_to project_settings_operations_path(@project)
        else
          render 'show'
        end
      end

      def render_update_json_response(result)
        if result[:status] == :success
          flash[:notice] = _('Your changes have been saved')
          render json: {
            status: result[:status]
          }
        else
          render(
            status: result[:http_status] || :bad_request,
            json: {
              status: result[:status],
              message: result[:message]
            }
          )
        end
      end

      def error_tracking_setting
        @error_tracking_setting ||= project.error_tracking_setting ||
          project.build_error_tracking_setting
      end

      def update_params
        params.require(:project).permit(permitted_project_params)
      end

      # overridden in EE
      def permitted_project_params
        project_params = {
          incident_management_setting_attributes: ::Gitlab::Tracking::IncidentManagement.tracking_keys.keys,

          metrics_setting_attributes: [:external_dashboard_url, :dashboard_timezone],

          error_tracking_setting_attributes: [
            :enabled,
            :api_host,
            :token,
            project: [:slug, :name, :organization_slug, :organization_name]
          ],

          grafana_integration_attributes: [:token, :grafana_url, :enabled]
        }

        if Feature.enabled?(:settings_operations_prometheus_service, project)
          project_params[:prometheus_integration_attributes] = [:manual_configuration, :api_url]
        end

        project_params
      end
    end
  end
end

Projects::Settings::OperationsController.prepend_if_ee('::EE::Projects::Settings::OperationsController')
