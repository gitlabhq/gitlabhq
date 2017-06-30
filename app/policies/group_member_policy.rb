class GroupMemberPolicy < BasePolicy
  delegate :group

  with_scope :subject
  condition(:last_owner) { @subject.group.last_owner?(@subject.user) }

  desc "Membership is users' own"
  with_score 0
  condition(:is_target_user) { @user && @subject.user_id == @user.id }

  rule { anonymous }.prevent_all
  rule { last_owner }.prevent_all

  rule { can?(:admin_group_member) }.policy do
    enable :update_group_member
    enable :destroy_group_member
  end

  rule { is_target_user }.policy do
    enable :destroy_group_member
  end
end
