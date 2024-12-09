# frozen_string_literal: true

module Projects::ProjectMembersHelper
  def project_members_app_data_json(...)
    project_members_app_data(...).to_json
  end

  def project_member_header_subtext(project)
    if can?(current_user, :admin_project_member, project)
      share_project_description(project)
    else
      ERB::Util.html_escape(_("Members can be added by project " \
        "%{i_open}Maintainers%{i_close} or %{i_open}Owners%{i_close}")) % {
          i_open: '<i>'.html_safe, i_close: '</i>'.html_safe
        }
    end
  end

  private

  def project_members_app_data(
    project, members:, invited:, access_requests:, include_relations:, search:, pending_members_count: # rubocop:disable Lint/UnusedMethodArgument -- Argument used in EE
  )
    {
      user: project_members_list_data(project, members, { param_name: :page, params: { search_groups: nil } }),
      group: project_group_links_list_data(project, include_relations, search),
      invite: project_members_list_data(project, invited.nil? ? [] : invited),
      access_request: project_members_list_data(project, access_requests.nil? ? [] : access_requests),
      source_id: project.id,
      can_manage_members: Ability.allowed?(current_user, :admin_project_member, project),
      can_manage_access_requests: Ability.allowed?(current_user, :admin_member_access_request, project),
      group_name: project.group&.name,
      group_path: project.group&.full_path,
      project_path: project.full_path,
      can_approve_access_requests: true, # true for CE, overridden in EE
      available_roles: available_project_roles(project)
    }
  end

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

    ERB::Util.html_escape(description) % { project_name: tag.strong(project.name) }
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

  def project_group_links_list_data(project, include_relations, search)
    members = []

    if include_relations.include?(:direct)
      project_group_links = project.project_group_links
      project_group_links = project_group_links.search(search) if search
      members += project_group_links_serialized(project, project_group_links)
    end

    if include_relations.include?(:inherited)
      group_group_links = project.group_group_links.distinct_on_shared_with_group_id_with_group_access
      group_group_links = group_group_links.search(search, include_parents: true) if search
      members += group_group_links_serialized(project, group_group_links)
    end

    if project_group_links.present? && group_group_links.present?
      members = members.sort_by { |m| -m.dig(:access_level, :integer_value).to_i }
                       .uniq { |m| m.dig(:shared_with_group, :id) }
    end

    {
      members: members,
      pagination: members_pagination_data(members),
      member_path: project_group_link_path(project, ':id')
    }
  end

  # Overridden in `ee/app/helpers/ee/projects/project_members_helper.rb`
  def available_project_roles(_)
    Gitlab::Access.options_with_owner.map do |name, access_level|
      { title: name, value: "static-#{access_level}" }
    end
  end
end

Projects::ProjectMembersHelper.prepend_mod_with('Projects::ProjectMembersHelper')
