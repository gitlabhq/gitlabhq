# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class CheckRuleExistenceService < BaseProjectService
      SUCCESS_RESPONSE_RULE_EXISTS = ServiceResponse.success(payload: { protection_rule_exists?: true }).freeze
      SUCCESS_RESPONSE_RULE_DOESNT_EXIST = ServiceResponse.success(payload: { protection_rule_exists?: false }).freeze

      ERROR_RESPONSE_UNAUTHORIZED = ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized).freeze

      def self.for_delete(params:, **args)
        new(params: params.merge(action: :delete), **args)
      end

      def initialize(params:, **args)
        raise(ArgumentError, 'Invalid param :action') unless params[:action].in?([:push, :delete])

        super
      end

      def execute
        return ERROR_RESPONSE_UNAUTHORIZED unless current_user_can_do_action?

        return service_response_for(check_rule_exists_for_user) if current_user.is_a?(User)
        return service_response_for(check_rule_exists_for_deploy_token) if current_user.is_a?(DeployToken)

        raise ArgumentError, 'Invalid user'
      end

      private

      def current_user_can_do_action?
        if params[:action] == :push
          can?(current_user, :create_container_image, project)
        else
          can?(current_user, :destroy_container_image, project)
        end
      end

      def check_rule_exists_for_user
        return false if current_user.can_admin_all_resources?

        project.container_registry_protection_rules.for_action_exists?(
          action: params[:action],
          access_level: project.team.max_member_access(current_user.id),
          repository_path: params[:repository_path]
        )
      end

      def check_rule_exists_for_deploy_token
        project.container_registry_protection_rules
               .for_repository_path(params[:repository_path])
               .exists?
      end

      def service_response_for(protection_rule_exists)
        protection_rule_exists ? SUCCESS_RESPONSE_RULE_EXISTS : SUCCESS_RESPONSE_RULE_DOESNT_EXIST
      end
    end
  end
end
