module Gitlab
  module ProjectAuthorizations
    # Calculating new project authorizations when supporting nested groups.
    #
    # This class relies on Common Table Expressions to efficiently get all data,
    # including data for nested groups. As a result this class can only be used
    # on PostgreSQL.
    class WithNestedGroups
      attr_reader :user

      # user - The User object for which to calculate the authorizations.
      def initialize(user)
        @user = user
      end

      def calculate
        cte = recursive_cte
        cte_alias = cte.table.alias(Group.table_name)
        projects = Project.arel_table
        links = ProjectGroupLink.arel_table

        relations = [
          # The project a user has direct access to.
          user.projects.select_for_project_authorization,

          # The personal projects of the user.
          user.personal_projects.select_as_maintainer_for_project_authorization,

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
            .select([links[:project_id],
                     least(cte_alias[:access_level],
                           links[:group_access],
                           'access_level')])
            .from(cte_alias)
            .joins('INNER JOIN project_group_links ON project_group_links.group_id = namespaces.id')
            .joins('INNER JOIN projects ON projects.id = project_group_links.project_id')
            .joins('INNER JOIN namespaces p_ns ON p_ns.id = projects.namespace_id')
            .where('p_ns.share_with_group_lock IS FALSE')
        ]

        ProjectAuthorization
          .unscoped
          .with
          .recursive(cte.to_arel)
          .select_from_union(relations)
      end

      private

      # Builds a recursive CTE that gets all the groups the current user has
      # access to, including any nested groups.
      def recursive_cte
        cte = Gitlab::SQL::RecursiveCTE.new(:namespaces_cte)
        members = Member.arel_table
        namespaces = Namespace.arel_table

        # Namespaces the user is a member of.
        cte << user.groups
          .select([namespaces[:id], members[:access_level]])
          .except(:order)

        # Sub groups of any groups the user is a member of.
        cte << Group.select([namespaces[:id],
                             greatest(members[:access_level],
                                      cte.table[:access_level], 'access_level')])
          .joins(join_cte(cte))
          .joins(join_members)
          .except(:order)

        cte
      end

      # Builds a LEFT JOIN to join optional memberships onto the CTE.
      def join_members
        members = Member.arel_table
        namespaces = Namespace.arel_table

        cond = members[:source_id]
          .eq(namespaces[:id])
          .and(members[:source_type].eq('Namespace'))
          .and(members[:requested_at].eq(nil))
          .and(members[:user_id].eq(user.id))

        Arel::Nodes::OuterJoin.new(members, Arel::Nodes::On.new(cond))
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
end
