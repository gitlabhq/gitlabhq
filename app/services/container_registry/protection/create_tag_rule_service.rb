# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class CreateTagRuleService < BaseService
      ALLOWED_ATTRIBUTES = %i[
        tag_name_pattern
        minimum_access_level_for_push
        minimum_access_level_for_delete
      ].freeze

      def execute
        unless can?(current_user, :admin_container_image, project)
          error_message = _('Unauthorized to create a protection rule for container image tags')
          return service_response_error(message: error_message)
        end

        protection_rule =
          project.container_registry_protection_tag_rules.create(params.slice(*ALLOWED_ATTRIBUTES))

        return service_response_error(message: protection_rule.errors.full_messages) unless protection_rule.persisted?

        ServiceResponse.success(payload: { container_protection_tag_rule: protection_rule })
      rescue ArgumentError => e
        service_response_error(message: e.message)
      end

      private

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { container_protection_tag_rule: nil }
        )
      end
    end
  end
end
