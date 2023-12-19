# frozen_string_literal: true

module ServiceDesk
  module CustomEmails
    class BaseService < ::BaseProjectService
      include Logger

      private

      def legitimate_user?
        can?(current_user, :admin_project, project)
      end

      def setting?
        project.service_desk_setting.present?
      end

      def credential?
        project.service_desk_custom_email_verification.present?
      end

      def verification?
        project.service_desk_custom_email_credential.present?
      end

      def error_user_not_authorized
        error_response(s_('ServiceDesk|User cannot manage project.'))
      end

      def error_response(message)
        log_warning(error_message: message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
