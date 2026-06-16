# frozen_string_literal: true

# Used to filter Organizations by set of params
#
# Arguments:
#   current_user - which user is requesting organizations
#   params:
#     search: string
#     exclude_default: boolean
#     state: string or array of strings - filter by organization state(s).
#       Valid values are the keys of Organizations::Organization.states
#       (e.g. 'active', 'soft_deleted', 'deletion_in_progress').
#       Invalid values are silently discarded; when no valid value remains
#       (i.e. every given state is invalid) no organizations are returned.
#       Non-admins can filter by state, but organizations being deleted
#       (soft_deleted, deletion_in_progress) are always excluded for them.
#       Admins can filter by any state, including the deletion states.
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
      organizations
        .then { |o| by_state(o) }
        .then { |o| by_exclude_default(o) }
        .then { |o| by_search(o) }
    end

    def by_state(organizations)
      # Non-admins never see organizations that are being deleted. Both admins and
      # non-admins can additionally filter by state via the `state` param.
      organizations = organizations.excluding_deletion_states unless can_read_all_resources?

      return organizations unless params[:state].present?

      # with_states discards unknown states; when none remain it returns nothing.
      organizations.with_states(params[:state])
    end

    def can_read_all_resources?
      current_user&.can_read_all_resources?
    end

    def by_exclude_default(items)
      return items unless params[:exclude_default]

      items.without_default
    end

    def by_search(items)
      return items unless params[:search].present?

      items.search(params[:search])
    end
  end
end
