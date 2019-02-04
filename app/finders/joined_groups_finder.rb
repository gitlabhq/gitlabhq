# frozen_string_literal: true

class JoinedGroupsFinder
  def initialize(user)
    @user = user
  end

  # Finds the groups of the source user, optionally limited to those visible to
  # the current user.
  def execute(current_user = nil)
    @user.authorized_groups
      .public_or_visible_to_user(current_user)
      .order_id_desc
  end
end
