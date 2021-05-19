# frozen_string_literal: true

class ProjectMemberPresenter < MemberPresenter
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
end

ProjectMemberPresenter.prepend_mod_with('ProjectMemberPresenter')
