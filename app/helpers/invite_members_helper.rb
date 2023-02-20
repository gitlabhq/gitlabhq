# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def can_invite_members_for_project?(project)
    # do not use the can_admin_project_member? helper here due to structure of the view and how membership_locked?
    # is leveraged for inviting groups
    can?(current_user, :admin_project_member, project)
  end

  def invite_accepted_notice(member)
    case member.source
    when Project
      _("You have been granted %{member_human_access} access to project %{name}.") %
        { member_human_access: member.human_access, name: member.source.name }
    when Group
      _("You have been granted %{member_human_access} access to group %{name}.") %
        { member_human_access: member.human_access, name: member.source.name }
    end
  end

  # Overridden in EE
  def common_invite_group_modal_data(source, member_class, is_project)
    {
      id: source.id,
      root_id: source.root_ancestor.id,
      name: source.name,
      default_access_level: Gitlab::Access::GUEST,
      invalid_groups: source.related_group_ids,
      help_link: help_page_url('user/permissions'),
      is_project: is_project,
      access_levels: member_class.permissible_access_level_roles(current_user, source).to_json,
      full_path: source.full_path
    }.merge(group_select_data(source))
  end

  # Overridden in EE
  def common_invite_modal_dataset(source)
    dataset = {
      id: source.id,
      root_id: source.root_ancestor&.id,
      name: source.name,
      default_access_level: Gitlab::Access::GUEST,
      full_path: source.full_path
    }

    if current_user && show_invite_members_for_task?(source)
      dataset.merge!(
        tasks_to_be_done_options: tasks_to_be_done_options.to_json,
        projects: projects_for_source(source).to_json,
        new_project_path: source.is_a?(Group) ? new_project_path(namespace_id: source.id) : ''
      )
    end

    dataset
  end

  private

  def group_select_data(source)
    if source.root_ancestor.prevent_sharing_groups_outside_hierarchy
      { groups_filter: 'descendant_groups', parent_id: source.root_ancestor.id }
    else
      {}
    end
  end

  # Overridden in EE
  def users_filter_data(group)
    {}
  end

  # Overridden in EE
  def show_invite_members_for_task?(_source)
    params[:open_modal] == 'invite_members_for_task'
  end

  def tasks_to_be_done_options
    ::MemberTask::TASKS.keys.map { |task| { value: task, text: localized_tasks_to_be_done_choices[task] } }
  end

  def projects_for_source(source)
    projects = source.is_a?(Project) ? [source] : source.projects
    projects.map { |project| { id: project.id, title: project.title } }
  end
end

InviteMembersHelper.prepend_mod_with('InviteMembersHelper')
