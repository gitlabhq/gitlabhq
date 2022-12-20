# frozen_string_literal: true

class ProjectMemberPresenter < MemberPresenter
  presents ::ProjectMember

  def access_level_roles
    ProjectMember.permissible_access_level_roles(current_user, source)
  end

  def can_remove?
    # If this user is attempting to manage an Owner member and doesn't have permission, do not allow
    return can_manage_owners? if member.owner?

    super
  end

  def can_update?
    # If this user is attempting to manage an Owner member and doesn't have permission, do not allow
    return can_manage_owners? if member.owner?

    super
  end

  def last_owner?
    # all owners of a project in a group are removable.
    # but in personal projects, the namespace holder is not removable.
    member.holder_of_the_personal_namespace?
  end

  private

  def admin_member_permission
    :admin_project_member
  end

  def update_member_permission
    :update_project_member
  end

  def destroy_member_permission
    :destroy_project_member
  end

  def can_manage_owners?
    can?(current_user, :manage_owners, source)
  end
end

ProjectMemberPresenter.prepend_mod_with('ProjectMemberPresenter')
