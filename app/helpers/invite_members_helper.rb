# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def can_invite_members_for_project?(project)
    Feature.enabled?(:invite_members_group_modal, project.group) && can_manage_project_members?(project)
  end

  def can_invite_group_for_project?(project)
    Feature.enabled?(:invite_members_group_modal, project.group) && can_manage_project_members?(project) && project.allowed_to_share_with_group?
  end

  def directly_invite_members?
    strong_memoize(:directly_invite_members) do
      can_import_members?
    end
  end

  def invite_group_members?(group)
    experiment_enabled?(:invite_members_empty_group_version_a) && Ability.allowed?(current_user, :admin_group_member, group)
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
end
