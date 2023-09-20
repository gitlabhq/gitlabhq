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

      def feature_flag_enabled?
        Feature.enabled?(:service_desk_custom_email, project)
      end

      def error_user_not_authorized
        error_response(s_('ServiceDesk|User cannot manage project.'))
      end

      def error_feature_flag_disabled
        error_response('Feature flag service_desk_custom_email is not enabled')
      end

      def error_response(message)
        log_warning(error_message: message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
