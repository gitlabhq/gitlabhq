# frozen_string_literal: true

# This finder returns all users that are related to a given group because:
# 1. They are members of the group, its sub-groups, or its ancestor groups
# 2. They are members of a group that is invited to the group, its sub-groups, or its ancestors
# 3. They are members of a project that belongs to the group
# 4. They are members of a group that is invited to the group's descendant projects
#
# These users are not necessarily members of the given group and may not have access to the group
# so this should not be used for access control
module Autocomplete
  class GroupUsersFinder
    include Gitlab::Utils::StrongMemoize

    def initialize(group:)
      @group = group
    end

    def execute
      members = Member
        .with(group_hierarchy_cte.to_arel) # rubocop:disable CodeReuse/ActiveRecord
        .with(descendant_projects_cte.to_arel) # rubocop:disable CodeReuse/ActiveRecord
        .from_union(member_relations, remove_duplicates: false)

      User
        .id_in(members.select(:user_id))
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420387")
    end

    private

    def member_relations
      [
        members_from_group_hierarchy.select(:user_id),
        members_from_hierarchy_group_shares.select(:user_id),
        members_from_descendant_projects.select(:user_id),
        members_from_descendant_project_shares.select(:user_id)
      ]
    end

    def members_from_group_hierarchy
      GroupMember
        .with_source_id(group_hierarchy_ids)
        .without_invites_and_requests
    end

    def members_from_hierarchy_group_shares
      invited_groups = GroupGroupLink.for_shared_groups(group_hierarchy_ids).select(:shared_with_group_id)

      GroupMember
        .with_source_id(invited_groups)
        .without_invites_and_requests
    end

    def members_from_descendant_projects
      ProjectMember
        .with_source_id(descendant_project_ids)
        .without_invites_and_requests
    end

    def members_from_descendant_project_shares
      descendant_project_invited_groups = ProjectGroupLink.for_projects(descendant_project_ids).select(:group_id)

      GroupMember
        .with_source_id(descendant_project_invited_groups)
        .without_invites_and_requests
    end

    def group_hierarchy_cte
      Gitlab::SQL::CTE.new(:group_hierarchy, @group.self_and_hierarchy.select(:id))
    end
    strong_memoize_attr :group_hierarchy_cte

    def group_hierarchy_ids
      Namespace.from(group_hierarchy_cte.table).select(:id) # rubocop:disable CodeReuse/ActiveRecord
    end

    def descendant_projects_cte
      Gitlab::SQL::CTE.new(:descendant_projects, @group.all_projects.select(:id))
    end
    strong_memoize_attr :descendant_projects_cte

    def descendant_project_ids
      Project.from(descendant_projects_cte.table).select(:id) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end
