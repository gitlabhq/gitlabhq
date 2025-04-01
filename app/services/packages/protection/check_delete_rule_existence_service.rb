# frozen_string_literal: true

module Packages
  module Protection
    class CheckDeleteRuleExistenceService < BaseProjectService
      SUCCESS_RESPONSE_RULE_EXISTS = ServiceResponse.success(payload: { protection_rule_exists?: true }).freeze
      SUCCESS_RESPONSE_RULE_DOESNT_EXIST = ServiceResponse.success(payload: { protection_rule_exists?: false }).freeze

      ERROR_RESPONSE_UNAUTHORIZED = ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized).freeze
      ERROR_RESPONSE_INVALID_PACKAGE_TYPE = ServiceResponse.error(message: 'Invalid package type',
        reason: :invalid_package_type).freeze

      def execute
        return ERROR_RESPONSE_INVALID_PACKAGE_TYPE unless package_type_allowed?
        return ERROR_RESPONSE_UNAUTHORIZED unless current_user_can_destroy_package?
        return SUCCESS_RESPONSE_RULE_DOESNT_EXIST if current_user.can_admin_all_resources?

        response = project.package_protection_rules.for_delete_exists?(
          access_level: project.team.max_member_access(current_user.id),
          package_name: params[:package_name],
          package_type: params[:package_type]
        )

        service_response_for(response)
      end

      private

      def package_type_allowed?
        Packages::Protection::Rule.package_types.key?(params[:package_type])
      end

      def current_user_can_destroy_package?
        can?(current_user, :destroy_package, project)
      end

      def service_response_for(protection_rule_exists)
        protection_rule_exists ? SUCCESS_RESPONSE_RULE_EXISTS : SUCCESS_RESPONSE_RULE_DOESNT_EXIST
      end
    end
  end
end
