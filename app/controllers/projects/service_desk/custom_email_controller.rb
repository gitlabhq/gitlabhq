# frozen_string_literal: true

module Projects
  module ServiceDesk
    class CustomEmailController < Projects::ApplicationController
      before_action :authorize_admin_project!

      feature_category :service_desk
      urgency :low

      def create
        response = ::ServiceDesk::CustomEmails::CreateService.new(
          project: project,
          current_user: current_user,
          params: params
        ).execute

        json_response(service_response: response)
      end

      def update
        response = ServiceDeskSettings::UpdateService.new(project, current_user, update_setting_params).execute

        if response.error?
          json_response(
            error_message: s_("ServiceDesk|Cannot update custom email"),
            status: :unprocessable_entity
          )
          return
        end

        json_response
      end

      def destroy
        response = ::ServiceDesk::CustomEmails::DestroyService.new(
          project: project,
          current_user: current_user
        ).execute

        json_response(service_response: response)
      end

      def show
        json_response
      end

      private

      def update_setting_params
        params.permit(:custom_email_enabled)
      end

      def json_response(error_message: nil, status: :ok, service_response: nil)
        if service_response.present?
          status = service_response.success? ? :ok : :unprocessable_entity
          error_message = service_response.message
        end

        respond_to do |format|
          format.json { render json: custom_email_attributes(error_message: error_message), status: status }
        end
      end

      def custom_email_attributes(error_message:)
        setting = project.service_desk_setting

        {
          custom_email: setting&.custom_email,
          custom_email_enabled: setting&.custom_email_enabled || false,
          custom_email_verification_state: setting&.custom_email_verification&.state,
          custom_email_verification_error: setting&.custom_email_verification&.error,
          custom_email_smtp_address: setting&.custom_email_credential&.smtp_address,
          error_message: error_message
        }
      end
    end
  end
end
