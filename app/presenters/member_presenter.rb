# frozen_string_literal: true

class MemberPresenter < Gitlab::View::Presenter::Delegated
  presents :member

  def access_level_roles
    member.class.access_level_roles
  end

  def valid_level_roles
    return access_level_roles unless member.highest_group_member

    access_level_roles.reject do |_name, level|
      member.highest_group_member.access_level > level
    end
  end

  def can_resend_invite?
    invite? &&
      can?(current_user, admin_member_permission, source)
  end

  def can_update?
    can?(current_user, update_member_permission, member)
  end

  def can_remove?
    can?(current_user, destroy_member_permission, member)
  end

  def can_approve?
    request? && can_update?
  end

  # This functionality is only available in EE.
  def can_override?
    false
  end

  private

  def admin_member_permission
    raise NotImplementedError
  end

  def update_member_permission
    raise NotImplementedError
  end

  def destroy_member_permission
    raise NotImplementedError
  end
end

MemberPresenter.prepend_mod_with('MemberPresenter')
