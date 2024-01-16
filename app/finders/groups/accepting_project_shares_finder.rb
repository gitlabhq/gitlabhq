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

      groups = by_hierarchy(groups)
      groups = by_ignorable(groups)
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
      groups = GroupsFinder.new(current_user, min_access_level: Gitlab::Access::GUEST).execute

      # We move the result into a materialized CTE to improve query performance during text search.
      union_query = ::Group.from_union([groups])
      cte = Gitlab::SQL::CTE.new(:my_union_cte, union_query)
      Group.with(cte.to_arel).from(cte.alias_to(Group.arel_table)) # rubocop: disable CodeReuse/ActiveRecord -- CTE use
    end
    # rubocop: enable CodeReuse/Finder

    def can_share_project?
      Ability.allowed?(current_user, :admin_project, project_to_be_shared) &&
        project_to_be_shared.allowed_to_share_with_group?
    end

    def by_ignorable(groups)
      # groups already linked to this project or groups above the project's
      # current hierarchy needs to be ignored.
      groups.id_not_in(project_to_be_shared.related_group_ids)
    end

    def by_hierarchy(groups)
      return groups if project_to_be_shared.personal? || sharing_outside_hierarchy_allowed?

      groups.id_in(root_ancestor.self_and_descendants_ids)
    end

    def sharing_outside_hierarchy_allowed?
      !root_ancestor.prevent_sharing_groups_outside_hierarchy
    end

    def root_ancestor
      project_to_be_shared.root_ancestor
    end
  end
end
