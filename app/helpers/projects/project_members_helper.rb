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

  def project_members_app_data_json(project, members:, group_links:, invited:, access_requests:)
    {
      user: project_members_list_data(project, members, { param_name: :page, params: { search_groups: nil } }),
      group: project_group_links_list_data(project, group_links),
      invite: project_members_list_data(project, invited.nil? ? [] : invited),
      access_request: project_members_list_data(project, access_requests.nil? ? [] : access_requests),
      source_id: project.id,
      can_manage_members: can_manage_project_members?(project)
    }.to_json
  end

  private

  def project_members_serialized(project, members)
    MemberSerializer.new.represent(members, { current_user: current_user, group: project.group, source: project })
  end

  def project_group_links_serialized(group_links)
    GroupLink::ProjectGroupLinkSerializer.new.represent(group_links, { current_user: current_user })
  end

  def project_members_list_data(project, members, pagination = {})
    {
      members: project_members_serialized(project, members),
      pagination: members_pagination_data(members, pagination),
      member_path: project_project_member_path(project, ':id')
    }
  end

  def project_group_links_list_data(project, group_links)
    {
      members: project_group_links_serialized(group_links),
      pagination: members_pagination_data(group_links),
      member_path: project_group_link_path(project, ':id')
    }
  end
end
