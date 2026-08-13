# frozen_string_literal: true

module Projects::ProjectMembersHelper
  # Data payload assembly lives in `Projects::ProjectMembers::AppDataSerializer`;
  # this helper only wires the serializer to the view and renders HTML subtext.
  def project_members_app_data_json(project, members:, **members_kwargs)
    project_members_app_data_serializer(project, members).app_data(**members_kwargs).to_json
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

  def project_members_app_data_serializer(project, members)
    Projects::ProjectMembers::AppDataSerializer.new(
      project,
      current_user: current_user,
      members: members,
      direct_members_filter_params: direct_members_filter_params
    )
  end

  def direct_members_filter_params
    permitted = params.permit(:search_direct_members, :max_role)

    { search: permitted[:search_direct_members], max_role: permitted[:max_role] }
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
end

Projects::ProjectMembersHelper.prepend_mod_with('Projects::ProjectMembersHelper')
