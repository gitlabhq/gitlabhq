# frozen_string_literal: true

module Projects::ProjectMembersHelper
  def can_manage_project_members?(project)
    can?(current_user, :admin_project_member, project)
  end

  def show_groups?(group_links)
    group_links.exists? || groups_tab_active?
  end

  def show_invited_members?(project, invited_members)
    can_manage_project_members?(project) && invited_members.exists?
  end

  def show_access_requests?(project, requesters)
    can_manage_project_members?(project) && requesters.exists?
  end

  def groups_tab_active?
    params[:search_groups].present?
  end

  def current_user_is_group_owner?(project)
    return false if project.group.nil?

    project.group.has_owner?(current_user)
  end
end
