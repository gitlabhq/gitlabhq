# frozen_string_literal: true

module Groups::GroupMembersHelper
  include AvatarsHelper

  AVATAR_SIZE = 40

  def group_member_select_options
    { multiple: true, class: 'input-clamp qa-member-select-field ', scope: :all, email_user: true }
  end

  def render_invite_member_for_group(group, default_access_level)
    render 'shared/members/invite_member', submit_url: group_group_members_path(group), access_levels: group.access_level_roles, default_access_level: default_access_level
  end

  def linked_groups_data_json(group_links)
    GroupGroupLinkSerializer.new.represent(group_links, { current_user: current_user }).to_json
  end

  def members_data_json(group, members)
    MemberSerializer.new.represent(members, { current_user: current_user, group: group }).to_json
  end

  # Overridden in `ee/app/helpers/ee/groups/group_members_helper.rb`
  def group_members_list_data_attributes(group, members)
    {
      members: members_data_json(group, members),
      member_path: group_group_member_path(group, ':id'),
      group_id: group.id,
      can_manage_members: can?(current_user, :admin_group_member, group).to_s
    }
  end

  def linked_groups_list_data_attributes(group)
    {
      members: linked_groups_data_json(group.shared_with_group_links),
      member_path: group_group_link_path(group, ':id'),
      group_id: group.id
    }
  end
end

Groups::GroupMembersHelper.prepend_if_ee('EE::Groups::GroupMembersHelper')
