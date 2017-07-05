class ProjectMemberPolicy < BasePolicy
  delegate { @subject.project }

  condition(:target_is_owner, scope: :subject) { @subject.user == @subject.project.owner }
  condition(:target_is_self) { @user && @subject.user == @user }

  rule { anonymous }.prevent_all
  rule { target_is_owner }.prevent_all

  rule { can?(:admin_project_member) }.policy do
    enable :update_project_member
    enable :destroy_project_member
  end

  rule { target_is_self }.enable :destroy_project_member
end
