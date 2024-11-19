# frozen_string_literal: true

module Packages
  module Protection
    class CheckRuleExistenceService < BaseProjectService
      SUCCESS_RESPONSE_RULE_EXISTS = ServiceResponse.success(payload: { protection_rule_exists?: true }).freeze
      SUCCESS_RESPONSE_RULE_DOESNT_EXIST = ServiceResponse.success(payload: { protection_rule_exists?: false }).freeze

      ERROR_RESPONSE_UNAUTHORIZED = ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized).freeze
      ERROR_RESPONSE_INVALID_PACKAGE_TYPE = ServiceResponse.error(message: 'Invalid package type',
        reason: :invalid_package_type).freeze

      def execute
        return ERROR_RESPONSE_INVALID_PACKAGE_TYPE unless package_type_allowed?
        return ERROR_RESPONSE_UNAUTHORIZED unless current_user_can_create_package?

        return service_response_for(check_rule_exists_for_user) if current_user.is_a?(User)
        return service_response_for(check_rule_exists_for_deploy_token) if current_user.is_a?(DeployToken)

        raise ArgumentError, "Invalid user"
      end

      private

      def package_type_allowed?
        Packages::Protection::Rule.package_types.key?(params[:package_type])
      end

      def current_user_can_create_package?
        can?(current_user, :create_package, project)
      end

      def check_rule_exists_for_user
        return false if current_user.can_admin_all_resources?

        user_project_authorization_access_level = current_user.max_member_access_for_project(project.id)
        project.package_protection_rules
        .for_push_exists?(
          access_level: user_project_authorization_access_level,
          package_name: params[:package_name],
          package_type: params[:package_type]
        )
      end

      def check_rule_exists_for_deploy_token
        project.package_protection_rules
               .for_package_type(params[:package_type])
               .for_package_name(params[:package_name])
               .exists?
      end

      def service_response_for(protection_rule_exists)
        protection_rule_exists ? SUCCESS_RESPONSE_RULE_EXISTS : SUCCESS_RESPONSE_RULE_DOESNT_EXIST
      end
    end
  end
end
