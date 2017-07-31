class ProjectAccessRequestPolicy < BasePolicy
  delegate :project

  with_scope :subject

  desc "ProjectAccessRequest is users' own"
  with_score 0
  condition(:is_target_user) { @user && @subject.user == @user }

  rule { anonymous }.prevent_all

  rule { can?(:admin_project_member) }.policy do
    enable :destroy_project_access_request
  end

  rule { is_target_user }.policy do
    enable :destroy_project_access_request
  end
end
