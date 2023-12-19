# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class DeleteRuleService
      include Gitlab::Allowable

      def initialize(container_registry_protection_rule, current_user:)
        if container_registry_protection_rule.blank? || current_user.blank?
          raise ArgumentError,
            'container_registry_protection_rule and current_user must be set'
        end

        @container_registry_protection_rule = container_registry_protection_rule
        @current_user = current_user
      end

      def execute
        unless can?(current_user, :admin_container_image, container_registry_protection_rule.project)
          error_message = _('Unauthorized to delete a container registry protection rule')
          return service_response_error(message: error_message)
        end

        deleted_container_registry_protection_rule = container_registry_protection_rule.destroy!

        ServiceResponse.success(
          payload: { container_registry_protection_rule: deleted_container_registry_protection_rule }
        )
      rescue StandardError => e
        service_response_error(message: e.message)
      end

      private

      attr_reader :container_registry_protection_rule, :current_user

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { container_registry_protection_rule: nil }
        )
      end
    end
  end
end
