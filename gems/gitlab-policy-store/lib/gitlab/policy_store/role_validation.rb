# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module RoleValidation
      ROLES_KEY = 'roles'

      private

      # Validates that roles in require_approval actions are valid for the trigger type.
      # CD roles can only be used with deployment triggers.
      def validate_action_roles!(attributes)
        return unless attributes.key?(:actions)

        actions = attributes[:actions]
        return unless actions.is_a?(Array)

        trigger_type = attributes[:trigger_type]

        actions.each_with_index do |action, index|
          next unless action.is_a?(Hash) && action['type'] == Actions::REQUIRE_APPROVAL

          validate_approval_roles!(action, trigger_type, index)
        end
      end

      def validate_approval_roles!(action, trigger_type, action_index)
        value = action['value']
        roles = value.is_a?(Hash) ? value[ROLES_KEY] : nil
        return if roles.nil? || !roles.is_a?(Array) || roles.empty?

        invalid_roles = roles - Roles.all_role_ids
        unless invalid_roles.empty?
          raise ValidationError, "action #{action_index}: invalid roles: #{invalid_roles.join(', ')}"
        end

        is_deployment_trigger = Roles::DEPLOYMENT_TRIGGERS.include?(trigger_type)

        # CD roles can only be used with deployment triggers
        cd_roles_used = roles & Roles.cd_role_ids
        if cd_roles_used.any? && !is_deployment_trigger
          raise ValidationError,
            "action #{action_index}: CD roles (#{cd_roles_used.join(', ')}) " \
              "can only be used with deployment triggers"
        end

        # GitLab roles can only be used with non-deployment triggers
        gitlab_roles_used = roles & Roles.gitlab_role_ids
        return unless gitlab_roles_used.any? && is_deployment_trigger

        raise ValidationError,
          "action #{action_index}: GitLab roles (#{gitlab_roles_used.join(', ')}) " \
            "cannot be used with deployment triggers, use CD roles instead"
      end
    end
  end
end
