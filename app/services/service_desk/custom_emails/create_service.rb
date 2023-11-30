# frozen_string_literal: true

module ServiceDesk
  module CustomEmails
    class CreateService < BaseService
      def execute
        return error_user_not_authorized unless legitimate_user?
        return error_params_missing unless has_required_params?
        return error_custom_email_exists if credential? || verification?

        return error_cannot_create_custom_email unless create_credential

        if update_settings.error?
          # We don't warp everything in a single transaction here and roll it back
          # because ServiceDeskSettings::UpdateService uses safe_find_or_create_by!
          rollback_credential
          return error_cannot_create_custom_email
        end

        project.reset

        # The create service may return an error response if the verification fails early.
        # Here We want to indicate whether adding a custom email address was successful, so
        # we don't use its response here.
        create_verification

        log_info
        ServiceResponse.success
      end

      private

      def update_settings
        ServiceDeskSettings::UpdateService.new(project, current_user, create_setting_params).execute
      end

      def rollback_credential
        ::ServiceDesk::CustomEmailCredential.find_by_project_id(project.id)&.destroy
      end

      def create_credential
        credential = ::ServiceDesk::CustomEmailCredential.new(create_credential_params.merge(project: project))
        credential.save
      rescue ArgumentError
        false
      end

      def create_verification
        ::ServiceDesk::CustomEmailVerifications::CreateService.new(project: project, current_user: current_user).execute
      end

      def create_setting_params
        ensure_params.permit(:custom_email)
      end

      def create_credential_params
        ensure_params.permit(:smtp_address, :smtp_port, :smtp_username, :smtp_password, :smtp_authentication)
      end

      def ensure_params
        return params if params.is_a?(ActionController::Parameters)

        ActionController::Parameters.new(params)
      end

      def has_required_params?
        required_keys.all? { |key| params.key?(key) && params[key].present? }
      end

      def required_keys
        %i[custom_email smtp_address smtp_port smtp_username smtp_password]
      end

      def error_custom_email_exists
        error_response(s_('ServiceDesk|Custom email already exists'))
      end

      def error_params_missing
        error_response(s_('ServiceDesk|Parameters missing'))
      end

      def error_cannot_create_custom_email
        error_response(s_('ServiceDesk|Cannot create custom email'))
      end
    end
  end
end
