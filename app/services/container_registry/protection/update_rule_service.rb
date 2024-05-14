# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class UpdateRuleService
      include Gitlab::Allowable

      ALLOWED_ATTRIBUTES = %i[
        repository_path_pattern
        minimum_access_level_for_delete
        minimum_access_level_for_push
      ].freeze

      def initialize(container_registry_protection_rule, current_user:, params:)
        if container_registry_protection_rule.blank? || current_user.blank?
          raise ArgumentError,
            'container_registry_protection_rule and current_user must be set'
        end

        @container_registry_protection_rule = container_registry_protection_rule
        @current_user = current_user
        @params = params || {}
      end

      def execute
        unless can?(current_user, :admin_container_image, container_registry_protection_rule.project)
          error_message = _('Unauthorized to update a container registry protection rule')
          return service_response_error(message: error_message)
        end

        container_registry_protection_rule.update(params.slice(*ALLOWED_ATTRIBUTES))

        if container_registry_protection_rule.errors.present?
          return service_response_error(message: container_registry_protection_rule.errors.full_messages)
        end

        ServiceResponse.success(payload: { container_registry_protection_rule: container_registry_protection_rule })
      rescue StandardError => e
        service_response_error(message: e.message)
      end

      private

      attr_reader :container_registry_protection_rule, :current_user, :params

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { container_registry_protection_rule: nil }
        )
      end
    end
  end
end
