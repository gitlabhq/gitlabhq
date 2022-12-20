# frozen_string_literal: true

class GroupMemberPresenter < MemberPresenter
  presents ::GroupMember

  def last_owner?
    member.last_owner_of_the_group?
  end

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

GroupMemberPresenter.prepend_mod_with('GroupMemberPresenter')
