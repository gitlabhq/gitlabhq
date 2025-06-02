# frozen_string_literal: true

module Packages
  module Protection
    class CheckRuleExistenceService < BaseProjectService
      SUCCESS_RESPONSE_RULE_EXISTS = ServiceResponse.success(payload: { protection_rule_exists?: true }).freeze
      SUCCESS_RESPONSE_RULE_DOESNT_EXIST = ServiceResponse.success(payload: { protection_rule_exists?: false }).freeze

      ERROR_RESPONSE_UNAUTHORIZED = ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized).freeze
      ERROR_RESPONSE_INVALID_PACKAGE_TYPE = ServiceResponse.error(message: 'Invalid package type',
        reason: :invalid_package_type).freeze

      def self.for_push(params:, **args)
        new(params: params.merge(action: :push), **args)
      end

      def self.for_delete(params:, **args)
        new(params: params.merge(action: :delete), **args)
      end

      def initialize(params:, **args)
        raise(ArgumentError, 'Invalid param :action') unless params[:action].in?([:push, :delete])

        super
      end

      def execute
        return ERROR_RESPONSE_INVALID_PACKAGE_TYPE unless package_type_allowed?
        return service_response_for(check_rule_exists_for_deploy_token_or_blank_user) if current_user.blank?
        return ERROR_RESPONSE_UNAUTHORIZED unless current_user_can_do_action?

        return service_response_for(check_rule_exists_for_user) if current_user.is_a?(User)
        return service_response_for(check_rule_exists_for_deploy_token_or_blank_user) if current_user.is_a?(DeployToken)

        raise ArgumentError, 'Invalid user'
      end

      private

      def package_type_allowed?
        Packages::Protection::Rule.package_types.key?(params[:package_type])
      end

      def current_user_can_do_action?
        case params[:action]
        when :push then can?(current_user, :create_package, project)
        when :delete then can?(current_user, :destroy_package, project)
        end
      end

      def check_rule_exists_for_user
        return false if current_user.can_admin_all_resources?

        project.package_protection_rules.for_action_exists?(
          action: params[:action],
          access_level: project.team.max_member_access(current_user.id),
          package_name: params[:package_name],
          package_type: params[:package_type]
        )
      end

      def check_rule_exists_for_deploy_token_or_blank_user
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
