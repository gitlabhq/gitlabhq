# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class CreateTagRuleService < BaseProjectService
      ALLOWED_ATTRIBUTES = %i[
        tag_name_pattern
        minimum_access_level_for_push
        minimum_access_level_for_delete
      ].freeze

      def execute
        unless can?(current_user, :admin_container_image, project)
          return service_response_error(message: _('Unauthorized to create a protection rule for container image tags'))
        end

        unless tag_rule_count_less_than_maximum?
          return service_response_error(message: _('Maximum number of protection rules have been reached.'))
        end

        unless ::ContainerRegistry::GitlabApiClient.supports_gitlab_api?
          return service_response_error(message: _('GitLab container registry API not supported'))
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

      def tag_rule_count_less_than_maximum?
        limit = ContainerRegistry::Protection::TagRule::MAX_TAG_RULES_PER_PROJECT

        project.container_registry_protection_tag_rules.limit(limit).count < limit
      end
    end
  end
end
