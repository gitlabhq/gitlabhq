# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class UpdateTagRuleService
      include Gitlab::Allowable

      ALLOWED_ATTRIBUTES = %i[
        tag_name_pattern
        minimum_access_level_for_delete
        minimum_access_level_for_push
      ].freeze

      def initialize(container_protection_tag_rule, current_user:, params:)
        if container_protection_tag_rule.blank? || current_user.blank?
          raise ArgumentError,
            'container_protection_tag_rule and current_user must be set'
        end

        @container_protection_tag_rule = container_protection_tag_rule
        @current_user = current_user
        @params = params || {}
      end

      def execute
        unless can?(current_user, :admin_container_image, container_protection_tag_rule.project)
          return service_response_error(message: _('Unauthorized to update a protection rule for container image tags'))
        end

        unless ::ContainerRegistry::GitlabApiClient.supports_gitlab_api?
          return service_response_error(message: _('GitLab container registry API not supported'))
        end

        unless container_protection_tag_rule.update(params.slice(*ALLOWED_ATTRIBUTES))
          return service_response_error(message: container_protection_tag_rule.errors.full_messages)
        end

        ServiceResponse.success(payload: { container_protection_tag_rule: container_protection_tag_rule })
      rescue ArgumentError => e
        service_response_error(message: e.message)
      end

      private

      attr_reader :container_protection_tag_rule, :current_user, :params

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { container_protection_tag_rule: nil }
        )
      end
    end
  end
end
