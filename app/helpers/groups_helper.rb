module GroupsHelper
  def remove_user_from_group_message(group, user)
    "Are you sure you want to remove \"#{user.name}\" from \"#{group.name}\"?"
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

  def group_head_title
    title = @group.name

    title = if current_action?(:issues)
              "Issues - " + title
            elsif current_action?(:merge_requests)
              "Merge requests - " + title
            elsif current_action?(:members)
              "Members - " + title
            elsif current_action?(:edit)
              "Settings - " + title
            else
              title
            end

    title
  end

  def group_settings_page?
    if current_controller?('groups')
      current_action?('edit') || current_action?('projects')
    else
      false
    end
  end
end
