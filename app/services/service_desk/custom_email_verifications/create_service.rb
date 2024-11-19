# frozen_string_literal: true

module ServiceDesk
  module CustomEmailVerifications
    class CreateService < BaseService
      SMTP_HOST_ERRORS = [
        SocketError,
        OpenSSL::SSL::SSLError,
        Net::SMTPServerBusy,
        Net::SMTPSyntaxError,
        Net::SMTPFatalError,
        Net::SMTPUnsupportedCommand,
        Net::SMTPUnknownError
      ].freeze

      def execute
        return error_settings_missing unless settings.present?
        return error_user_not_authorized unless can?(current_user, :admin_project, project)

        update_settings
        notify_project_owners_and_user_about_verification_start
        ramp_up_error = send_verification_email_and_catch_delivery_errors

        if ramp_up_error
          handle_error_case(ramp_up_error)
        else
          log_info
          ServiceResponse.success
        end
      end

      private

      def verification
        @verification ||= settings.custom_email_verification ||
          ServiceDesk::CustomEmailVerification.new(project_id: settings.project_id)
      end

      def update_settings
        settings.update!(custom_email_enabled: false) if settings.custom_email_enabled?

        verification.mark_as_started!(current_user)
        # We use verification association from project, to use it in email, we need to reset it here.
        project.reset
      end

      def notify_project_owners_and_user_about_verification_start
        notify_project_owners_and_user_with_email(
          email_method_name: :service_desk_verification_triggered_email,
          user: current_user
        )
      end

      def send_verification_email_and_catch_delivery_errors
        # Send this synchronously as we need to get direct feedback on delivery errors.
        Notify.service_desk_custom_email_verification_email(settings).deliver

        nil
      rescue *SMTP_HOST_ERRORS => error
        # e.g. host not found or host certificate issues
        assign_and_log_delivery_error(:smtp_host_issue, error)
      rescue Net::SMTPAuthenticationError => error
        # incorrect username or password
        assign_and_log_delivery_error(:invalid_credentials, error)
      rescue Net::ReadTimeout => error
        # Server is slow to respond
        assign_and_log_delivery_error(:read_timeout, error)
      end

      def assign_and_log_delivery_error(error_type, error)
        log_warning(error_message: error.message, error_class: error.class.to_s)

        error_type
      end

      def handle_error_case(ramp_up_error)
        notify_project_owners_and_user_about_result(user: current_user)

        verification.mark_as_failed!(ramp_up_error)

        error_not_verified(ramp_up_error)
      end

      def error_settings_missing
        error_response(s_('ServiceDesk|Service Desk setting missing'))
      end

      def error_user_not_authorized
        error_response(s_('ServiceDesk|User cannot manage project.'))
      end
    end
  end
end
