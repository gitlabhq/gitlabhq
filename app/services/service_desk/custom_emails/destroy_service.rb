# frozen_string_literal: true

module ServiceDesk
  module CustomEmails
    class DestroyService < BaseService
      def execute
        return error_user_not_authorized unless legitimate_user?
        return error_does_not_exist unless verification? || credential? || setting?

        project.service_desk_custom_email_verification&.destroy
        project.service_desk_custom_email_credential&.destroy
        project.reset
        project.service_desk_setting&.update!(custom_email: nil, custom_email_enabled: false)

        log_info
        ServiceResponse.success
      end

      private

      def error_does_not_exist
        error_response(s_('ServiceDesk|Custom email does not exist'))
      end
    end
  end
end
