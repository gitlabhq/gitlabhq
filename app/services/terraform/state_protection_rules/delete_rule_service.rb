# frozen_string_literal: true

module Terraform
  module StateProtectionRules
    class DeleteRuleService
      include Gitlab::Allowable

      def initialize(protection_rule, current_user:)
        raise ArgumentError, 'protection_rule and current_user must be set' if protection_rule.nil? || current_user.nil?

        @protection_rule = protection_rule
        @current_user = current_user
      end

      def execute
        unless can?(current_user, :delete_terraform_state_protection_rule, protection_rule.project)
          return service_response_error(
            message: _('Unauthorized to delete a Terraform state protection rule')
          )
        end

        if protection_rule.destroy
          ServiceResponse.success(payload: { terraform_state_protection_rule: protection_rule })
        else
          service_response_error(message: protection_rule.errors.full_messages)
        end
      end

      private

      attr_reader :protection_rule, :current_user

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { terraform_state_protection_rule: nil }
        )
      end
    end
  end
end
