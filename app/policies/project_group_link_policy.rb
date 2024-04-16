# frozen_string_literal: true

class ProjectGroupLinkPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:group_owner) { group_owner? }
  condition(:group_owner_or_project_admin) { group_owner? || project_admin? }
  condition(:can_read_group) { can?(:read_group, @subject.group) }
  condition(:can_manage_owners) { can_manage_owners? }
  condition(:can_manage_group_link_with_owner_access) do
    next true unless @subject.owner_access?

    can_manage_owners?
  end

  rule { can_manage_owners }.enable :manage_owners

  rule { can_manage_group_link_with_owner_access }.enable :manage_group_link_with_owner_access

  # `manage_destroy` specifies the very basic permission that a user needs to destroy a link.
  rule { group_owner_or_project_admin }.enable :manage_destroy

  # `destroy_project_group_link` combines the basic permission, ie `manage_destroy` AND
  #  the specific permissions a user needs to destroy a link that has `OWNER` access level.
  # link.project's owner, or link.group's owner can delete a link with any access level, including OWNER
  rule { can?(:manage_destroy) & (can?(:manage_group_link_with_owner_access) | group_owner) }.policy do
    enable :destroy_project_group_link
  end

  rule { can_read_group | group_owner_or_project_admin }.enable :read_shared_with_group

  private

  def can_manage_owners?
    can?(:manage_owners, @subject.project)
  end

  def group_owner?
    can?(:admin_group, @subject.group)
  end

  def project_admin?
    can?(:admin_project, @subject.project)
  end
end
