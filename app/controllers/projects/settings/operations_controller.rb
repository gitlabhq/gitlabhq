# frozen_string_literal: true

module Projects
  module Settings
    class OperationsController < Projects::ApplicationController
      before_action :authorize_admin_operations!

      helper_method :error_tracking_setting

      def show
      end

      def update
        result = ::Projects::Operations::UpdateService.new(project, current_user, update_params).execute

        track_events(result)
        render_update_response(result)
      end

      # overridden in EE
      def track_events(result)
      end

      private

      # overridden in EE
      def render_update_response(result)
        respond_to do |format|
          format.json do
            render_update_json_response(result)
          end
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
        {
          metrics_setting_attributes: [:external_dashboard_url],

          error_tracking_setting_attributes: [
            :enabled,
            :api_host,
            :token,
            project: [:slug, :name, :organization_slug, :organization_name]
          ],

          grafana_integration_attributes: [:token, :grafana_url, :enabled]
        }
      end
    end
  end
end

Projects::Settings::OperationsController.prepend_if_ee('::EE::Projects::Settings::OperationsController')
