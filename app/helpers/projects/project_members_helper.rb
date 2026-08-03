# frozen_string_literal: true

module Projects::ProjectMembersHelper
  include Groups::GroupMembersHelper

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

  # Public so the controller can reuse it to build the direct members JSON payload.
  def project_members_list_data(project, members, pagination = {})
    {
      members: project_members_serialized(project, members),
      pagination: members_pagination_data(members, pagination),
      member_path: project_project_member_path(project, ':id')
    }
  end

  private

  def project_members_app_data(
    project, members:, invited:, links:, access_requests:, pending_members_count: # rubocop:disable Lint/UnusedMethodArgument -- Argument used in EE
  )
    {
      user: project_members_list_data(project, members, { param_name: :page, params: { search_groups: nil } }),
      direct_members: direct_members_lazy_data(project),
      group: project_group_links_list_data(project, links),
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

  # The Direct members tab is lazy: it is seeded empty and fetches its rows from
  # `members_path` (the members index JSON endpoint) when the tab is activated.
  # This keeps the direct members rows/preloader off the initial page load.
  #
  # The total count is seeded via a single cheap COUNT so the tab count badge is
  # accurate immediately, without loading (and preloading) all member rows.
  def direct_members_lazy_data(project)
    seed = Kaminari.paginate_array([], total_count: direct_members_count(project))

    {
      members: [],
      pagination: members_pagination_data(seed, { param_name: :direct_members_page }),
      member_path: project_project_member_path(project, ':id'),
      members_path: project_project_members_path(project, format: :json)
    }
  end

  # Derive the seeded count from the same finder that produces the tab's rows
  # (see `Projects::ProjectMembersController#non_invited_direct_members`) so the
  # badge count and the loaded list share a single source of truth for "what is
  # a direct member". Using the association COUNT here would be a second, silently
  # divergent definition. The same search/max_role filter params are applied so a
  # seed served for a filtered URL matches the filtered rows the fetch will load.
  #
  # Kaminari's `total_count` is used (rather than a bare `count`) because it is
  # the same value `members_pagination_data` reports for the fetched list, and it
  # counts correctly when `Member.search` adds custom SELECT/ORDER expressions.
  def direct_members_count(project)
    MembersFinder
      .new(project, current_user, params: direct_members_count_params)
      .execute(include_relations: [:direct])
      .non_invite
      .page(1)
      .total_count
  end

  def direct_members_count_params
    permitted = params.permit(:search_direct_members, :max_role)

    { search: permitted[:search_direct_members], max_role: permitted[:max_role] }
  end

  def project_group_links_list_data(project, links)
    members = project_group_links_serialized(project, links.project_links)
    members += group_group_links_serialized(project, links.group_links)

    {
      members: members,
      pagination: members_pagination_data(links, { param_name: :page }),
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
