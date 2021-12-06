# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the user within the given groups and
  # stores the values in requests store.
  # Will only be able to preload max access level for groups where the user is a direct member
  class UserMaxAccessLevelInGroupsPreloader
    def initialize(groups, user)
      @groups = groups
      @user = user
    end

    def execute
      group_memberships = GroupMember.active_without_invites_and_requests
                                     .non_minimal_access
                                     .where(user: @user, source_id: @groups)
                                     .group(:source_id)
                                     .maximum(:access_level)

      @groups.each do |group|
        access_level = group_memberships[group.id]
        group.merge_value_to_request_store(User, @user.id, access_level) if access_level.present?
      end
    end
  end
end
