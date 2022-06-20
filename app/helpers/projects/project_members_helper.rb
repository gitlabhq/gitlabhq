# frozen_string_literal: true

module Projects::ProjectMembersHelper
  def project_members_app_data_json(project, members:, group_links:, invited:, access_requests:)
    {
      user: project_members_list_data(project, members, { param_name: :page, params: { search_groups: nil } }),
      group: project_group_links_list_data(project, group_links),
      invite: project_members_list_data(project, invited.nil? ? [] : invited),
      access_request: project_members_list_data(project, access_requests.nil? ? [] : access_requests),
      source_id: project.id,
      can_manage_members: Ability.allowed?(current_user, :admin_project_member, project)
    }.to_json
  end

  def project_member_header_subtext(project)
    if can?(current_user, :admin_project_member, project)
      share_project_description(project)
    else
      html_escape(_("Members can be added by project " \
                  "%{i_open}Maintainers%{i_close} or %{i_open}Owners%{i_close}")) % {
        i_open: '<i>'.html_safe, i_close: '</i>'.html_safe
      }
    end
  end

  private

  def share_project_description(project)
    share_with_group   = project.allowed_to_share_with_group?
    share_with_members = !membership_locked?

    description =
      if share_with_group && share_with_members
        _("You can invite a new member to %{project_name} or invite another group.")
      elsif share_with_group
        _("You can invite another group to %{project_name}.")
      elsif share_with_members
        _("You can invite a new member to %{project_name}.")
      end

    html_escape(description) % { project_name: tag.strong(project.name) }
  end

  def project_members_serialized(project, members)
    MemberSerializer.new.represent(members, { current_user: current_user, group: project.group, source: project })
  end

  def project_group_links_serialized(project, group_links)
    GroupLink::ProjectGroupLinkSerializer.new.represent(group_links, { current_user: current_user, source: project })
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
      members: project_group_links_serialized(project, group_links),
      pagination: members_pagination_data(group_links),
      member_path: project_group_link_path(project, ':id')
    }
  end
end

Projects::ProjectMembersHelper.prepend_mod_with('Projects::ProjectMembersHelper')
