# frozen_string_literal: true

# Used to filter Organizations by set of params
#
# Arguments:
#   current_user - which user is requesting organizations
#   params:
#     search: string
module Organizations
  class OrganizationsFinder
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      filter_organizations(base_scope)
    end

    private

    attr_reader :current_user, :params

    def base_scope
      return ::Organizations::Organization.public_only unless current_user
      return ::Organizations::Organization.all if current_user.can_read_all_resources?

      ::Organizations::Organization
         .public_to_user(current_user)
         .or(current_user.organizations)
    end

    def filter_organizations(organizations)
      by_search(organizations)
    end

    def by_search(items)
      return items unless params[:search].present?

      items.search(params[:search])
    end
  end
end
