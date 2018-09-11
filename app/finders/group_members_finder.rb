# frozen_string_literal: true

class GroupMembersFinder
  def initialize(group)
    @group = group
  end

  def execute(include_descendants: false)
    group_members = @group.members
    wheres = []

    return group_members unless @group.parent || include_descendants

    wheres << "members.id IN (#{group_members.select(:id).to_sql})"

    if @group.parent
      parents_members = GroupMember.non_request
        .where(source_id: @group.ancestors.select(:id))
        .where.not(user_id: @group.users.select(:id))

      wheres << "members.id IN (#{parents_members.select(:id).to_sql})"
    end

    if include_descendants
      descendant_members = GroupMember.non_request
        .where(source_id: @group.descendants.select(:id))
        .where.not(user_id: @group.users.select(:id))

      wheres << "members.id IN (#{descendant_members.select(:id).to_sql})"
    end

    GroupMember.where(wheres.join(' OR '))
  end
end
