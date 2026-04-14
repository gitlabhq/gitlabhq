# frozen_string_literal: true

module Terraform
  module StateProtectionRules
    class CheckRuleExistenceService < BaseProjectService
      SUCCESS_RESPONSE_PROTECTED =
        ServiceResponse.success(payload: { protection_rule_exists?: true }).freeze
      SUCCESS_RESPONSE_UNPROTECTED =
        ServiceResponse.success(payload: { protection_rule_exists?: false }).freeze

      def execute
        return SUCCESS_RESPONSE_UNPROTECTED if Feature.disabled?(:protected_terraform_states, project)

        rule = find_protection_rule
        return SUCCESS_RESPONSE_UNPROTECTED unless rule

        return SUCCESS_RESPONSE_UNPROTECTED if current_user&.can_admin_all_resources?

        return SUCCESS_RESPONSE_PROTECTED unless role_sufficient?(rule)
        return SUCCESS_RESPONSE_PROTECTED unless source_allowed?(rule)

        SUCCESS_RESPONSE_UNPROTECTED
      end

      private

      def find_protection_rule
        project.terraform_state_protection_rules.find_by_state_name(params[:state_name])
      end

      def role_sufficient?(rule)
        return false if current_user.blank?

        user_access_level = project.team.max_member_access(current_user.id)
        user_access_level >= rule.minimum_access_level_for_write_before_type_cast
      end

      def source_allowed?(rule)
        case rule.allowed_from
        when 'anywhere'
          true
        when 'ci_only'
          params[:current_authenticated_job].present?
        when 'ci_on_protected_branch_only'
          params[:current_authenticated_job]&.pipeline&.protected_ref?
        else
          false
        end
      end
    end
  end
end
