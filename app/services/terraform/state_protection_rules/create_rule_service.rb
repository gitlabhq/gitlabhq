# frozen_string_literal: true

module Terraform
  module StateProtectionRules
    class CreateRuleService < BaseProjectService
      ALLOWED_ATTRIBUTES = %i[
        state_name
        minimum_access_level_for_write
        allowed_from
      ].freeze

      def execute
        unless can?(current_user, :create_terraform_state_protection_rule, project)
          return service_response_error(message: _('Unauthorized to create a Terraform state protection rule'))
        end

        protection_rule = project.terraform_state_protection_rules.create(params.slice(*ALLOWED_ATTRIBUTES))

        return service_response_error(message: protection_rule.errors.full_messages) unless protection_rule.persisted?

        ServiceResponse.success(payload: { terraform_state_protection_rule: protection_rule })
      rescue ArgumentError, ActiveRecord::StatementInvalid => e
        service_response_error(message: e.message)
      end

      private

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { terraform_state_protection_rule: nil }
        )
      end
    end
  end
end
