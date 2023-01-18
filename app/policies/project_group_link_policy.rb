# frozen_string_literal: true

class ProjectGroupLinkPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:group_owner_or_project_admin) { group_owner? || project_admin? }

  rule { group_owner_or_project_admin }.enable :admin_project_group_link

  private

  def group_owner?
    can?(:admin_group, @subject.group)
  end

  def project_admin?
    can?(:admin_project, @subject.project)
  end
end
