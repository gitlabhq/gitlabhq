# frozen_string_literal: true

class GroupMembersFinder < UnionFinder
  def initialize(group)
    @group = group
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute(include_descendants: false)
    group_members = @group.members
    relations = []

    return group_members unless @group.parent || include_descendants

    relations << group_members

    if @group.parent
      parents_members = GroupMember.non_request
        .where(source_id: @group.ancestors.select(:id))
        .where.not(user_id: @group.users.select(:id))

      relations << parents_members
    end

    if include_descendants
      descendant_members = GroupMember.non_request
        .where(source_id: @group.descendants.select(:id))
        .where.not(user_id: @group.users.select(:id))

      relations << descendant_members
    end

    find_union(relations, GroupMember)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
