# frozen_string_literal: true

class ProjectGroupLinkPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:group_owner_or_project_admin) { group_owner? || project_admin? }
  condition(:can_read_group) { can?(:read_group, @subject.group) }
  condition(:project_member) { @subject.project.member?(@user) }

  rule { group_owner_or_project_admin }.enable :admin_project_group_link

  rule { can_read_group | project_member }.enable :read_shared_with_group

  private

  def group_owner?
    can?(:admin_group, @subject.group)
  end

  def project_admin?
    can?(:admin_project, @subject.project)
  end
end
