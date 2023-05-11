# frozen_string_literal: true

# This class relies on Common Table Expressions to efficiently get all data,
# including data for nested groups.
module Gitlab
  class ProjectAuthorizations
    attr_reader :user

    # user - The User object for which to calculate the authorizations.
    def initialize(user)
      @user = user
    end

    def calculate
      cte = if Feature.enabled?(:linear_project_authorization, user)
              linear_cte
            else
              recursive_cte
            end

      cte_alias = cte.table.alias(Group.table_name)
      projects = Project.arel_table
      links = ProjectGroupLink.arel_table

      relations = [
        # The project a user has direct access to.
        user.projects_with_active_memberships.select_for_project_authorization,

        # The personal projects of the user.
        user.personal_projects.select_project_owner_for_project_authorization,

        # Projects that belong directly to any of the groups the user has
        # access to.
        Namespace
          .unscoped
          .select([alias_as_column(projects[:id], 'project_id'),
                   cte_alias[:access_level]])
          .from(cte_alias)
          .joins(:projects),

        # Projects shared with any of the namespaces the user has access to.
        Namespace
          .unscoped
          .select([
                    links[:project_id],
                    least(cte_alias[:access_level], links[:group_access], 'access_level')
                  ])
          .from(cte_alias)
          .joins('INNER JOIN project_group_links ON project_group_links.group_id = namespaces.id')
          .joins('INNER JOIN projects ON projects.id = project_group_links.project_id')
          .joins('INNER JOIN namespaces p_ns ON p_ns.id = projects.namespace_id')
          .where('p_ns.share_with_group_lock IS FALSE')
      ]

      if Feature.enabled?(:linear_project_authorization, user)
        ProjectAuthorization
          .unscoped
          .with(cte.to_arel)
          .select_from_union(relations)
      else
        ProjectAuthorization
          .unscoped
          .with
          .recursive(cte.to_arel)
          .select_from_union(relations)
      end
    end

    private

    # Builds a recursive CTE that gets all the groups the current user has
    # access to, including any nested groups and any shared groups.
    def recursive_cte
      cte = Gitlab::SQL::RecursiveCTE.new(:namespaces_cte)
      members = Member.arel_table
      namespaces = Namespace.arel_table
      group_group_links = GroupGroupLink.arel_table

      # Namespaces the user is a member of.
      cte << user.groups_with_active_memberships
        .select([namespaces[:id], members[:access_level]])
        .except(:order)

      # Namespaces shared with any of the group
      cte << Group.select([namespaces[:id],
                           least(members[:access_level],
                                 group_group_links[:group_access],
                                 'access_level')])
                  .joins(join_group_group_links)
                  .joins(join_members_on_group_group_links)

      # Sub groups of any groups the user is a member of.
      cte << Group.select([
                            namespaces[:id],
                            greatest(members[:access_level], cte.table[:access_level], 'access_level')
                          ])
        .joins(join_cte(cte))
        .joins(join_members_on_namespaces)
        .except(:order)

      cte
    end

    def linear_cte
      # Groups shared with user and their parent groups
      shared_groups = Group
        .select("namespaces.id, MAX(LEAST(members.access_level, group_group_links.group_access)) as access_level")
        .joins("INNER JOIN group_group_links ON group_group_links.shared_group_id = namespaces.id
               OR namespaces.traversal_ids @> ARRAY[group_group_links.shared_group_id::int]")
        .joins("INNER JOIN members ON group_group_links.shared_with_group_id = members.source_id")
        .merge(user.group_members)
        .merge(GroupMember.active_state)
        .group("namespaces.id")

      # Groups the user is a member of and their parent groups.
      lateral_query = Group.as_ids.where("namespaces.traversal_ids @> ARRAY [members.source_id]")
      member_groups_with_ancestors = GroupMember.select("namespaces.id, MAX(members.access_level) as access_level")
        .joins("CROSS JOIN LATERAL (#{lateral_query.to_sql}) as namespaces")
        .group("namespaces.id")
        .merge(user.group_members)
        .merge(GroupMember.active_state)

      union = Namespace.from_union([shared_groups, member_groups_with_ancestors])

      Gitlab::SQL::CTE.new(:linear_namespaces_cte, union)
    end

    # Builds a LEFT JOIN to join optional memberships onto the CTE.
    def join_members_on_namespaces
      members = Member.arel_table
      namespaces = Namespace.arel_table

      cond = members[:source_id]
        .eq(namespaces[:id])
        .and(members[:source_type].eq('Namespace'))
        .and(members[:requested_at].eq(nil))
        .and(members[:user_id].eq(user.id))
        .and(members[:state].eq(::Member::STATE_ACTIVE))
        .and(members[:access_level].gt(Gitlab::Access::MINIMAL_ACCESS))

      Arel::Nodes::OuterJoin.new(members, Arel::Nodes::On.new(cond))
    end

    def join_group_group_links
      group_group_links = GroupGroupLink.arel_table
      namespaces = Namespace.arel_table

      cond = group_group_links[:shared_group_id].eq(namespaces[:id])
      Arel::Nodes::InnerJoin.new(group_group_links, Arel::Nodes::On.new(cond))
    end

    def join_members_on_group_group_links
      group_group_links = GroupGroupLink.arel_table
      members = Member.arel_table

      cond = group_group_links[:shared_with_group_id].eq(members[:source_id])
                    .and(members[:source_type].eq('Namespace'))
                    .and(members[:requested_at].eq(nil))
                    .and(members[:user_id].eq(user.id))
                    .and(members[:state].eq(::Member::STATE_ACTIVE))
                    .and(members[:access_level].gt(Gitlab::Access::MINIMAL_ACCESS))
      Arel::Nodes::InnerJoin.new(members, Arel::Nodes::On.new(cond))
    end

    # Builds an INNER JOIN to join namespaces onto the CTE.
    def join_cte(cte)
      namespaces = Namespace.arel_table
      cond = cte.table[:id].eq(namespaces[:parent_id])

      Arel::Nodes::InnerJoin.new(cte.table, Arel::Nodes::On.new(cond))
    end

    def greatest(left, right, column_alias)
      sql_function('GREATEST', [left, right], column_alias)
    end

    def least(left, right, column_alias)
      sql_function('LEAST', [left, right], column_alias)
    end

    def sql_function(name, args, column_alias)
      alias_as_column(Arel::Nodes::NamedFunction.new(name, args), column_alias)
    end

    def alias_as_column(value, alias_to)
      Arel::Nodes::As.new(value, Arel::Nodes::SqlLiteral.new(alias_to))
    end
  end
end
