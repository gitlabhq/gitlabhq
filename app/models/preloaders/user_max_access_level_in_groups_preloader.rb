# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the user within the given groups and
  # stores the values in requests store.
  class UserMaxAccessLevelInGroupsPreloader
    def initialize(groups, user)
      @groups = groups
      @user = user
    end

    def execute
      return unless @user

      preload_with_traversal_ids
    end

    private

    def preload_with_traversal_ids
      # Diagrammatic representation of this step:
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111157#note_1271550140
      max_access_levels = GroupMember.from_union(all_memberships)
                            .joins("INNER JOIN (#{traversal_join_sql}) as hierarchy ON members.source_id = hierarchy.traversal_id")
                            .group('hierarchy.id')
                            .maximum(:access_level)

      @groups.each do |group|
        max_access_level = max_access_levels[group.id] || Gitlab::Access::NO_ACCESS
        group.merge_value_to_request_store(User, @user.id, max_access_level)
      end
    end

    def all_memberships
      [
        direct_memberships.select(*GroupMember.cached_column_list),
        memberships_from_group_shares
      ]
    end

    def direct_memberships
      GroupMember.active_without_invites_and_requests.where(user: @user)
    end

    def memberships_from_group_shares
      alter_direct_memberships_to_make_it_act_like_memberships_in_shared_groups
    end

    def alter_direct_memberships_to_make_it_act_like_memberships_in_shared_groups
      group_group_link_table = GroupGroupLink.arel_table
      group_member_table = GroupMember.arel_table

      altered_columns = GroupMember.column_names.map do |column_name|
        case column_name
        when 'access_level'
          # Consider the limiting effect of group share's access level
          smallest_value_arel([group_group_link_table[:group_access], group_member_table[:access_level]], 'access_level')
        when 'source_id'
          # Alter the `source_id` of the `Member` record that is currently pointing to the `shared_with_group`
          # such that this record would now behave like a `Member` record of this user pointing to the `shared_group` group.
          Arel::Nodes::As.new(group_group_link_table[:shared_group_id], Arel::Nodes::SqlLiteral.new('source_id'))
        else
          group_member_table[column_name]
        end
      end

      direct_memberships_in_groups_that_have_been_shared_with_other_groups.select(*altered_columns)
    end

    def direct_memberships_in_groups_that_have_been_shared_with_other_groups
      direct_memberships.joins(
        "INNER JOIN group_group_links ON members.source_id = group_group_links.shared_with_group_id"
      )
    end

    def smallest_value_arel(args, column_alias)
      Arel::Nodes::As.new(
        Arel::Nodes::NamedFunction.new('LEAST', args),
        Arel::Nodes::SqlLiteral.new(column_alias))
    end

    def traversal_join_sql
      Namespace.select('id, unnest(traversal_ids) as traversal_id').where(id: @groups.map(&:id)).to_sql
    end
  end
end
