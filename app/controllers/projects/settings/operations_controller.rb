# frozen_string_literal: true

module Projects
  module Settings
    class OperationsController < Projects::ApplicationController
      layout 'project_settings'
      before_action :authorize_admin_operations!

      before_action do
        push_frontend_feature_flag(:integrated_error_tracking, project)
      end

      respond_to :json, only: [:reset_alerting_token, :reset_pagerduty_token]

      helper_method :error_tracking_setting

      feature_category :incident_management
      urgency :low

      def update
        result = ::Projects::Operations::UpdateService.new(project, current_user, update_params).execute

        track_events(result)
        render_update_response(result)
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

      def reset_pagerduty_token
        result = ::Projects::Operations::UpdateService
          .new(project, current_user, pagerduty_token_params)
          .execute

        if result[:status] == :success
          pagerduty_token = project.incident_management_setting&.pagerduty_token
          webhook_url = project_incidents_integrations_pagerduty_url(project, token: pagerduty_token)

          render json: { pagerduty_webhook_url: webhook_url, pagerduty_token: pagerduty_token }
        else
          render json: {}, status: :unprocessable_entity
        end
      end

      private

      def track_events(result)
        if result[:status] == :success
          ::Gitlab::Tracking::IncidentManagement.track_from_params(
            update_params[:incident_management_setting_attributes]
          )
        end
      end

      def alerting_params
        { alerting_setting_attributes: { regenerate_token: true } }
      end

      def pagerduty_token_params
        { incident_management_setting_attributes: { regenerate_token: true } }
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
        [
          incident_management_setting_attributes: ::Gitlab::Tracking::IncidentManagement.tracking_keys.keys,

          error_tracking_setting_attributes: [
            :enabled,
            :integrated,
            :api_host,
            :token,
            { project: [:slug, :name, :organization_slug, :organization_name, :sentry_project_id] }
          ]
        ]
      end
    end
  end
end

Projects::Settings::OperationsController.prepend_mod_with('Projects::Settings::OperationsController')
