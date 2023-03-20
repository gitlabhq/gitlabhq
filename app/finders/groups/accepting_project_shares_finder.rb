# frozen_string_literal: true

# AcceptingProjectSharesFinder
#
# Used to filter Shareable Groups by a set of params
#
# Arguments:
#   current_user - which user is requesting groups
#   params:
#     search: string
module Groups
  class AcceptingProjectSharesFinder < Base
    def initialize(current_user, project_to_be_shared, params = {})
      @current_user = current_user
      @params = params
      @project_to_be_shared = project_to_be_shared
    end

    def execute
      return Group.none unless can_share_project?

      groups = if has_admin_access?
                 Group.all
               else
                 groups_with_guest_access_plus
               end

      groups = by_search(groups)

      sort(groups).with_route
    end

    private

    attr_reader :current_user, :project_to_be_shared, :params

    def has_admin_access?
      current_user&.can_read_all_resources?
    end

    # rubocop: disable CodeReuse/Finder
    def groups_with_guest_access_plus
      GroupsFinder.new(current_user, min_access_level: Gitlab::Access::GUEST).execute
    end
    # rubocop: enable CodeReuse/Finder

    def can_share_project?
      Ability.allowed?(current_user, :admin_project, project_to_be_shared) &&
        project_to_be_shared.allowed_to_share_with_group?
    end
  end
end
