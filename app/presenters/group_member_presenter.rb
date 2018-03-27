class GroupMemberPresenter < MemberPresenter
  private

  def admin_member_permission
    :admin_group_member
  end

  def update_member_permission
    :update_group_member
  end

  def destroy_member_permission
    :destroy_group_member
  end
end
