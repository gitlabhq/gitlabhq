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

  def group_members_app_data_json(group, members:, invited:, access_requests:)
    {
      user: group_members_list_data(group, members, { param_name: :page, params: { invited_members_page: nil, search_invited: nil } }),
      group: group_group_links_list_data(group),
      invite: group_members_list_data(group, invited.nil? ? [] : invited, { param_name: :invited_members_page, params: { page: nil } }),
      access_request: group_members_list_data(group, access_requests.nil? ? [] : access_requests),
      source_id: group.id,
      can_manage_members: can?(current_user, :admin_group_member, group)
    }.to_json
  end

  private

  def group_members_serialized(group, members)
    MemberSerializer.new.represent(members, { current_user: current_user, group: group, source: group })
  end

  def group_group_links_serialized(group_links)
    GroupLink::GroupGroupLinkSerializer.new.represent(group_links, { current_user: current_user })
  end

  # Overridden in `ee/app/helpers/ee/groups/group_members_helper.rb`
  def group_members_list_data(group, members, pagination = {})
    {
      members: group_members_serialized(group, members),
      pagination: members_pagination_data(members, pagination),
      member_path: group_group_member_path(group, ':id')
    }
  end

  def group_group_links_list_data(group)
    group_links = group.shared_with_group_links

    {
      members: group_group_links_serialized(group_links),
      pagination: members_pagination_data(group_links),
      member_path: group_group_link_path(group, ':id')
    }
  end
end

Groups::GroupMembersHelper.prepend_mod_with('Groups::GroupMembersHelper')
