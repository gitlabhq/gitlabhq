# frozen_string_literal: true

module Preloaders
  # This class preloads the max access level (role) for the user within the given groups and
  # stores the values in requests store.
  class UserMaxAccessLevelInGroupsPreloader
    def initialize(groups, user)
      @groups = groups
      @user = user
    end

    def execute
      if ::Feature.enabled?(:use_traversal_ids, default_enabled: :yaml)
        preload_with_traversal_ids
      else
        preload_direct_memberships
      end
    end

    private

    def preload_direct_memberships
      group_memberships = GroupMember.active_without_invites_and_requests
                                     .where(user: @user, source_id: @groups)
                                     .group(:source_id)
                                     .maximum(:access_level)

      @groups.each do |group|
        access_level = group_memberships[group.id]
        group.merge_value_to_request_store(User, @user.id, access_level) if access_level.present?
      end
    end

    def preload_with_traversal_ids
      max_access_levels = GroupMember.active_without_invites_and_requests
                                     .where(user: @user)
                                     .joins("INNER JOIN (#{traversal_join_sql}) as hierarchy ON members.source_id = hierarchy.traversal_id")
                                     .group('hierarchy.id')
                                     .maximum(:access_level)

      @groups.each do |group|
        max_access_level = max_access_levels[group.id] || Gitlab::Access::NO_ACCESS
        group.merge_value_to_request_store(User, @user.id, max_access_level)
      end
    end

    def traversal_join_sql
      Namespace.select('id, unnest(traversal_ids) as traversal_id').where(id: @groups.map(&:id)).to_sql
    end
  end
end
