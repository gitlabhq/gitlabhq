class GroupMembersFinder < Projects::ApplicationController
  def initialize(group)
    @group = group
  end

  def execute
    group_members = @group.members

    return group_members unless @group.parent

    parents_members = GroupMember.non_request.
      where(source_id: @group.ancestors.select(:id)).
      where.not(user_id: @group.users.select(:id))

    wheres = ["members.id IN (#{group_members.select(:id).to_sql})"]
    wheres << "members.id IN (#{parents_members.select(:id).to_sql})"

    GroupMember.where(wheres.join(' OR '))
  end
end
