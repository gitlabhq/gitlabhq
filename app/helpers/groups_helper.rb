module GroupsHelper
  def remove_user_from_group_message(group, user)
    "Are you sure you want to remove \"#{user.name}\" from \"#{group.name}\"?"
  end

  def leave_group_message(group)
    "Are you sure you want to leave \"#{group}\" group?"
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
end
