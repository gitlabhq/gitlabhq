class MembersFinder < Projects::ApplicationController
  def initialize(project_members, group)
    @project_members = project_members
    @group = group
  end

  def execute
    non_null_user_ids = @project_members.where.not(user_id: nil).select(:user_id)
    group_members = @group.group_members.where.not(user_id: non_null_user_ids)
    group_members = group_members.non_invite unless can?(current_user, :admin_group, @group)
    group_members
  end
end
