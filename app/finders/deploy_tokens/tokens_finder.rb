# frozen_string_literal: true

# Arguments:
#   current_user: The currently logged in user.
#   scope: A Project or Group to scope deploy tokens to (or :all for all tokens).
#   params:
#     active: Boolean - When true, only return active deployments.
module DeployTokens
  class TokensFinder
    attr_reader :current_user, :params, :scope

    def initialize(current_user, scope, params = {})
      @current_user = current_user
      @scope = scope
      @params = params
    end

    def execute
      by_active(init_collection)
    end

    private

    def init_collection
      case scope
      when Group, Project
        raise Gitlab::Access::AccessDeniedError unless current_user.can?(:read_deploy_token, scope)

        scope.deploy_tokens
      when :all
        raise Gitlab::Access::AccessDeniedError unless current_user.can_read_all_resources?

        DeployToken.all
      else
        raise ArgumentError, "Scope must be a Group, a Project, or the :all symbol."
      end
    end

    def by_active(items)
      params[:active] ? items.active : items
    end
  end
end
