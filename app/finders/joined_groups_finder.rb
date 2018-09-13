# frozen_string_literal: true

class JoinedGroupsFinder < UnionFinder
  def initialize(user)
    @user = user
  end

  # Finds the groups of the source user, optionally limited to those visible to
  # the current user.
  def execute(current_user = nil)
    segments = all_groups(current_user)

    find_union(segments, Group).order_id_desc
  end

  private

  def all_groups(current_user)
    groups = []

    groups << @user.authorized_groups.visible_to_user(current_user) if current_user
    groups << @user.authorized_groups.public_to_user(current_user)

    groups
  end
end
