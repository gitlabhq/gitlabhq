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
    # This should only be used for groups to load the invite group modal.
    # For instance the invite groups modal should not call this from a project scope
    # this is only to be called in scope of a group context as noted in this thread
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79036#note_821465513
    # the group sharing in projects disabling is explained there as well
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
      default_access_level: Gitlab::Access::GUEST,
      invalid_groups: source.related_group_ids
    }

    if show_invite_members_for_task?(source)
      dataset.merge!(
        tasks_to_be_done_options: tasks_to_be_done_options.to_json,
        projects: projects_for_source(source).to_json,
        new_project_path: source.is_a?(Group) ? new_project_path(namespace_id: source.id) : ''
      )
    end

    dataset
  end

  private

  # Overridden in EE
  def users_filter_data(group)
    {}
  end

  def show_invite_members_for_task?(source)
    return unless current_user

    invite_for_help_continuous_onboarding = source.is_a?(Project) && experiment(:invite_for_help_continuous_onboarding, namespace: source.namespace).variant.name == 'candidate'
    params[:open_modal] == 'invite_members_for_task' || invite_for_help_continuous_onboarding
  end

  def tasks_to_be_done_options
    ::MemberTask::TASKS.keys.map { |task| { value: task, text: localized_tasks_to_be_done_choices[task] } }
  end

  def projects_for_source(source)
    projects = source.is_a?(Project) ? [source] : source.projects
    projects.map { |project| { id: project.id, title: project.title } }
  end
end
