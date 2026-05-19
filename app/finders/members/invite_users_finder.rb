# frozen_string_literal: true

# Used for searching users that can be added to group/project members
#
# Arguments:
#   current_user - which user use
#   resource - group or project
#   search: string
module Members
  class InviteUsersFinder < UsersFinder
    attr_reader :resource

    def initialize(current_user, resource, organization_id:, search: nil)
      @current_user = current_user
      @resource = resource
      @params = { search: search, organization_id: organization_id }
    end

    def base_scope
      users = User.active.without_project_bot

      users = scope_for_resource(users)

      users.order_id_desc
    end

    def scope_for_resource(users)
      ::Members::ServiceAccounts::EligibilityChecker.new(**checker_args).filter_users(users)
    end

    private

    def checker_args
      case resource
      when Project then { target_project: resource }
      when Group then { target_group: resource }
      else {}
      end
    end
  end
end

Members::InviteUsersFinder.prepend_mod
