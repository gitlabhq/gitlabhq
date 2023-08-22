# frozen_string_literal: true

module ServiceDesk
  module CustomEmails
    class BaseService < ::BaseProjectService
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
        with_context do
          Gitlab::AppLogger.warn(build_log_message(error_message: message))
        end
        ServiceResponse.error(message: message)
      end

      def log_info(error_message: nil)
        with_context do
          Gitlab::AppLogger.info(build_log_message(error_message: error_message))
        end
      end

      def with_context(&block)
        Gitlab::ApplicationContext.with_context(
          related_class: self.class.to_s,
          user: current_user,
          project: project,
          &block
        )
      end

      def build_log_message(error_message: nil)
        {
          category: 'custom_email',
          error_message: error_message
        }.compact
      end
    end
  end
end
