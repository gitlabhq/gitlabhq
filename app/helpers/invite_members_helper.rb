# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def can_invite_members_for_project?(project)
    # Do not use the invite_member policy here due to structure of the view and how membership_locked?
    # is leveraged for inviting groups
    can?(current_user, :invite_project_members, project)
  end

  def invite_accepted_notice(member)
    format(
      _('You have been granted access to the %{source_name} %{source_type} with the following role: %{role_name}.'),
      source_name: member.source.name,
      source_type: member.source.model_name.singular,
      role_name: member.present.human_access
    )
  end

  # Overridden in EE
  def common_invite_group_modal_data(source, member_class)
    {
      id: source.id,
      root_id: source.root_ancestor.id,
      name: source.name,
      default_access_level: Gitlab::Access::GUEST,
      invalid_groups: source.related_group_ids,
      help_link: help_page_url('user/permissions.md'),
      is_project: source.is_a?(Project).to_s,
      access_levels: member_class.permissible_access_level_roles(current_user, source).to_json,
      full_path: source.full_path
    }.merge(group_select_data(source))
  end

  # Overridden in EE
  def common_invite_modal_dataset(source)
    {
      id: source.id,
      root_id: source.root_ancestor&.id,
      name: source.name,
      default_access_level: Gitlab::Access::GUEST,
      full_path: source.full_path
    }
  end

  private

  def group_select_data(source)
    if source.root_ancestor.prevent_sharing_groups_outside_hierarchy
      { groups_filter: 'descendant_groups', parent_id: source.root_ancestor.id }
    else
      {}
    end
  end
end

InviteMembersHelper.prepend_mod_with('InviteMembersHelper')
