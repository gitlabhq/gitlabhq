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
    members_data(group, members).to_json
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

  private

  def members_data(group, members)
    members.map do |member|
      user = member.user
      source = member.source

      data = {
        id: member.id,
        created_at: member.created_at,
        expires_at: member.expires_at&.to_time,
        requested_at: member.requested_at,
        can_update: member.can_update?,
        can_remove: member.can_remove?,
        access_level: {
          string_value: member.human_access,
          integer_value: member.access_level
        },
        source: {
          id: source.id,
          name: source.full_name,
          web_url: Gitlab::UrlBuilder.build(source)
        },
        valid_roles: member.valid_level_roles
      }.merge(member_created_by_data(member.created_by))

      if member.invite?
        data[:invite] = member_invite_data(member)
      elsif user.present?
        data[:user] = member_user_data(user)
      end

      data
    end
  end

  def member_created_by_data(created_by)
    return {} unless created_by.present?

    {
      created_by: {
        name: created_by.name,
        web_url: Gitlab::UrlBuilder.build(created_by)
      }
    }
  end

  def member_user_data(user)
    {
      id: user.id,
      name: user.name,
      username: user.username,
      web_url: Gitlab::UrlBuilder.build(user),
      avatar_url: avatar_icon_for_user(user, AVATAR_SIZE),
      blocked: user.blocked?,
      two_factor_enabled: user.two_factor_enabled?
    }.merge(member_user_status_data(user.status))
  end

  def member_user_status_data(status)
    return {} unless status.present?

    {
      status: {
        emoji: status.emoji,
        message_html: status.message_html
      }
    }
  end

  def member_invite_data(member)
    {
      email: member.invite_email,
      avatar_url: avatar_icon_for_email(member.invite_email, AVATAR_SIZE),
      can_resend: member.can_resend_invite?
    }
  end
end

Groups::GroupMembersHelper.prepend_if_ee('EE::Groups::GroupMembersHelper')
