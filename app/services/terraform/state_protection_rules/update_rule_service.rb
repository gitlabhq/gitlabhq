# frozen_string_literal: true

module Terraform
  module StateProtectionRules
    class UpdateRuleService
      include Gitlab::Allowable

      ALLOWED_ATTRIBUTES = %i[
        state_name
        minimum_access_level_for_write
        allowed_from
      ].freeze

      def initialize(protection_rule, current_user:, params: {})
        if protection_rule.blank? || current_user.blank?
          raise ArgumentError, 'protection_rule and current_user must be set'
        end

        @protection_rule = protection_rule
        @current_user = current_user
        @params = params
      end

      def execute
        unless can?(current_user, :admin_terraform_state, protection_rule.project)
          return service_response_error(
            message: _('Unauthorized to update a Terraform state protection rule')
          )
        end

        if protection_rule.update(params.slice(*ALLOWED_ATTRIBUTES))
          ServiceResponse.success(payload: { terraform_state_protection_rule: protection_rule })
        else
          service_response_error(message: protection_rule.errors.full_messages)
        end
      end

      private

      attr_reader :protection_rule, :current_user, :params

      def service_response_error(message:)
        ServiceResponse.error(
          message: message,
          payload: { terraform_state_protection_rule: nil }
        )
      end
    end
  end
end
