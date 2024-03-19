# frozen_string_literal: true

module Members
  class MembersWithParents
    attr_reader :group

    def initialize(group)
      @group = group
    end

    # Returns all members for group and parents, with no filters
    def all_members
      GroupMember.from_union([
        members_from_self_and_ancestors,
        members_from_self_and_ancestor_group_shares
      ])
    end

    # Returns members based on filter options:
    #
    #   - `active_users`. DEPRECATED. If true, returns only members for active users
    #   - `minimal_access`. Used only in EE (GitLab Premium). If true, returns
    #      members which has minimal access. If false (default), does not return
    #      members with minimal access
    #
    # NOTE : this method does not return pending invites, nor requests.
    def members(active_users: false, minimal_access: false)
      raise ArgumentError, 'active_users: is deprecated' if active_users && minimal_access

      group_hierarchy_members = members_from_self_and_ancestors

      group_hierarchy_members =
        if active_users
          group_hierarchy_members.active_without_invites_and_requests
        else
          filter_invites_and_requests(group_hierarchy_members, minimal_access)
        end

      GroupMember.from_union([
        group_hierarchy_members,
        members_from_self_and_ancestor_group_shares
      ])
    end

    private

    # NOTE: minimal access is Premium, so in FOSS we will not include minimal access member
    def filter_invites_and_requests(members, _minimal_access)
      members.without_invites_and_requests(minimal_access: false)
    end

    def source_ids
      # Avoids an unnecessary SELECT when the group has no parents
      @source_ids ||=
        if group.has_parent?
          group.self_and_ancestors.reorder(nil).select(:id)
        else
          group.id
        end
    end

    def members_from_self_and_ancestors
      GroupMember
        .with_source_id(source_ids)
        .select(*GroupMember.cached_column_list)
    end

    def members_from_self_and_ancestor_group_shares
      group_group_link_table = GroupGroupLink.arel_table
      group_member_table = GroupMember.arel_table

      group_group_links_query = GroupGroupLink.where(shared_group_id: source_ids)
      cte = Gitlab::SQL::CTE.new(:group_group_links_cte, group_group_links_query)
      cte_alias = cte.table.alias(GroupGroupLink.table_name)

      # Instead of members.access_level, we need to maximize that access_level at
      # the respective group_group_links.group_access.
      member_columns = GroupMember.column_names.map do |column_name|
        if column_name == 'access_level'
          smallest_value_arel([cte_alias[:group_access], group_member_table[:access_level]], 'access_level')
        else
          group_member_table[column_name]
        end
      end

      GroupMember
        .with(cte.to_arel)
        .select(*member_columns)
        .from([group_member_table, cte.alias_to(group_group_link_table)])
        .where(group_member_table[:requested_at].eq(nil))
        .where(group_member_table[:source_id].eq(group_group_link_table[:shared_with_group_id]))
        .where(group_member_table[:source_type].eq('Namespace'))
        .where(group_member_table[:state].eq(::Member::STATE_ACTIVE))
        .non_minimal_access
    end

    def smallest_value_arel(args, column_alias)
      Arel::Nodes::As.new(
        Arel::Nodes::NamedFunction.new('LEAST', args),
        Arel::Nodes::SqlLiteral.new(column_alias))
    end
  end
end

Members::MembersWithParents.prepend_mod
