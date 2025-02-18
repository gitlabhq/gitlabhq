# frozen_string_literal: true

module ServiceDesk
  module CustomEmailVerifications
    class UpdateService < BaseService
      EMAIL_TOKEN_REGEXP = /Verification token: ([A-Za-z0-9_-]{12})/

      def execute
        return error_parameter_missing if settings.blank? || verification.blank?
        return error_already_finished if verification.finished?
        return error_already_failed if already_failed_and_no_mail?

        verification_error = verify

        settings.update!(custom_email_enabled: false) if settings.custom_email_enabled?

        notify_project_owners_and_user_about_result(user: verification.triggerer)

        if verification_error.present?
          verification.mark_as_failed!(verification_error)

          error_not_verified(verification_error)
        else
          verification.mark_as_finished!

          log_info
          ServiceResponse.success
        end
      end

      private

      def mail
        params[:mail]
      end

      def verification
        @verification ||= settings.custom_email_verification
      end

      def already_failed_and_no_mail?
        verification.failed? && mail.blank?
      end

      def verify
        return :mail_not_received_within_timeframe if mail_not_received_within_timeframe?
        return :incorrect_forwarding_target if forwarded_to_service_desk_alias_address?
        return :incorrect_from if incorrect_from?
        return :incorrect_token if incorrect_token?

        nil
      end

      def mail_not_received_within_timeframe?
        # (For completeness) also raise if no email provided
        mail.blank? || !verification.in_timeframe?
      end

      def forwarded_to_service_desk_alias_address?
        return false unless Gitlab::Email::ServiceDeskEmail.enabled?

        # Users must use the Service Desk address created from `incoming_email`
        # so all reply by email features work as expected.
        # Using the Service Desk alias address generated from `service_desk_email`
        # doesn't allow to ingest email replies, so we'd always add a new issue.
        alias_address = ::ServiceDesk::Emails.new(project).alias_address
        addresses_from_headers.include?(alias_address)
      end

      def incorrect_from?
        # Does the email forwarder preserve the FROM header?
        mail.from.first != settings.custom_email
      end

      def incorrect_token?
        message, _stripped_text = Gitlab::Email::ReplyParser.new(mail).execute

        scan_result = message.scan(EMAIL_TOKEN_REGEXP)

        return true if scan_result.empty?

        scan_result.first.first != verification.token
      end

      def addresses_from_headers
        # Common headers for forwarding target addresses are
        # `To` and `Delivered-To`. We may expand that list if necessary.
        (Array(mail.to) + Array(mail['Delivered-To']).map(&:value)).uniq
      end

      def error_parameter_missing
        error_response(s_('ServiceDesk|Service Desk setting or verification object missing'))
      end

      def error_already_finished
        error_response(s_('ServiceDesk|Custom email address has already been verified.'))
      end

      def error_already_failed
        error_response(s_('ServiceDesk|Custom email address verification has already been processed and failed.'))
      end
    end
  end
end
