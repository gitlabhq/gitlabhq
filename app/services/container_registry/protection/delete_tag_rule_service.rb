# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class DeleteTagRuleService
      include Gitlab::Allowable

      def initialize(container_protection_tag_rule, current_user:)
        if container_protection_tag_rule.blank? || current_user.blank?
          raise ArgumentError,
            _('container_protection_tag_rule and current_user must be set')
        end

        @container_protection_tag_rule = container_protection_tag_rule
        @current_user = current_user
      end

      def execute
        unless can?(current_user, :admin_container_image, container_protection_tag_rule.project)
          return service_response_error(message: _('Unauthorized to delete a protection rule for container image tags'))
        end

        unless ::ContainerRegistry::GitlabApiClient.supports_gitlab_api?
          return service_response_error(message: _('GitLab container registry API not supported'))
        end

        deleted_container_protection_tag_rule = container_protection_tag_rule.destroy!

        ServiceResponse.success(
          payload: { container_protection_tag_rule: deleted_container_protection_tag_rule }
        )
      end

      private

      attr_reader :container_protection_tag_rule, :current_user

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { container_protection_tag_rule: nil }
        )
      end
    end
  end
end
