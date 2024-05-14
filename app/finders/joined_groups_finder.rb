# frozen_string_literal: true

class JoinedGroupsFinder
  def initialize(user)
    @user = user
  end

  # Finds the groups of the source user, optionally limited to those visible to
  # the current user.
  def execute(current_user = nil)
    @user
      .authorized_groups
      .with_non_archived_projects
      .with_non_invite_group_members
      .public_or_visible_to_user(current_user)
      .with_route
      .order_id_desc
  end
end
