class GroupMemberPolicy < BasePolicy
  def target_user
    @subject.user
  end

  def group
    @subject.group
  end

  delegate { group }

  condition(:last_owner) { group.last_owner?(target_user) }

  desc "Membership is users' own"
  condition(:is_target_user) { target_user == @user }

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
