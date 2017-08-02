class GroupAccessRequestPolicy < BasePolicy
  delegate :group

  with_scope :subject

  desc "GroupAccessRequest is users' own"
  with_score 0
  condition(:is_target_user) { @user && @subject.user == @user }

  rule { anonymous }.prevent_all

  rule { can?(:admin_group_member) }.policy do
    enable :update_group_access_request
    enable :destroy_group_access_request
  end

  rule { is_target_user }.policy do
    enable :destroy_group_access_request
  end
end
