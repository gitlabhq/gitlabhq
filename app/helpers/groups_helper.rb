module GroupsHelper
  def remove_user_from_group_message(group, member)
    if member.user
      "Are you sure you want to remove \"#{member.user.name}\" from \"#{group.name}\"?"
    else
      "Are you sure you want to revoke the invitation for \"#{member.invite_email}\" to join \"#{group.name}\"?"
    end
  end

  def leave_group_message(group)
    "Are you sure you want to leave \"#{group}\" group?"
  end

  def should_user_see_group_roles?(user, group)
    if user
      user.is_admin? || group.members.exists?(user_id: user.id)
    else
      false
    end
  end

  def group_icon(group)
    if group.is_a?(String)
      group = Group.find_by(path: group)
    end

    if group && group.avatar.present?
      group.avatar.url
    else
      'no_group_avatar.png'
    end
  end

  def group_title(group, name = nil, url = nil)
    full_title = link_to(simple_sanitize(group.name), group_path(group))
    full_title += ' &middot; '.html_safe + link_to(simple_sanitize(name), url) if name

    content_tag :span do
      full_title
    end
  end
end
