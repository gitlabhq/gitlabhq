# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def can_invite_members_for_project?(project)
    # do not use the can_admin_project_member? helper here due to structure of the view and how membership_locked?
    # is leveraged for inviting groups
    Feature.enabled?(:invite_members_group_modal, project.group) && can?(current_user, :admin_project_member, project)
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

  def group_select_data(group)
    if group.root_ancestor.namespace_settings.prevent_sharing_groups_outside_hierarchy
      { groups_filter: 'descendant_groups', parent_id: group.root_ancestor.id }
    else
      {}
    end
  end

  def common_invite_modal_dataset(source)
    dataset = {
      id: source.id,
      name: source.name,
      default_access_level: Gitlab::Access::GUEST
    }

    experiment(:member_areas_of_focus, user: current_user) do |e|
      e.publish_to_database

      e.control { dataset.merge!(areas_of_focus_options: [], no_selection_areas_of_focus: []) }
      e.candidate { dataset.merge!(areas_of_focus_options: member_areas_of_focus_options.to_json, no_selection_areas_of_focus: ['no_selection']) }
    end

    if show_invite_members_for_task?
      dataset.merge!(
        tasks_to_be_done_options: tasks_to_be_done_options.to_json,
        projects: projects_for_source(source).to_json,
        new_project_path: source.is_a?(Group) ? new_project_path(namespace_id: source.id) : ''
      )
    end

    dataset
  end

  private

  def member_areas_of_focus_options
    [
      {
        value: 'Contribute to the codebase', text: s_('InviteMembersModal|Contribute to the codebase')
      },
      {
        value: 'Collaborate on open issues and merge requests', text: s_('InviteMembersModal|Collaborate on open issues and merge requests')
      },
      {
        value: 'Configure CI/CD', text: s_('InviteMembersModal|Configure CI/CD')
      },
      {
        value: 'Configure security features', text: s_('InviteMembersModal|Configure security features')
      },
      {
        value: 'Other', text: s_('InviteMembersModal|Other')
      }
    ]
  end

  # Overridden in EE
  def users_filter_data(group)
    {}
  end

  def show_invite_members_for_task?
    return unless current_user && experiment(:invite_members_for_task).enabled?

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
