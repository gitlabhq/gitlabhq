class MembersFinder < Projects::ApplicationController
  def initialize(project_members, project_group)
    @project_members = project_members
    @project_group = project_group
  end

  def execute(current_user)
    non_null_user_ids = @project_members.where.not(user_id: nil).select(:user_id)
    group_members = @project_group.group_members.where.not(user_id: non_null_user_ids)
    group_members = group_members.non_invite unless can?(current_user, :admin_group,  @project_group)
    group_members
  end
end
