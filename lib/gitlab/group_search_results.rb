# frozen_string_literal: true

module Gitlab
  class GroupSearchResults < SearchResults
    attr_reader :group

    def initialize(current_user, query, limit_projects = nil, group:, **opts)
      @group = group
      super(
        current_user,
        query,
        limit_projects,
        default_project_filter: opts.fetch(:default_project_filter, false),
        order_by: opts.fetch(:order_by, nil),
        sort: opts.fetch(:sort, nil),
        filters: opts.fetch(:filters, {})
      )
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users
      groups = group.self_and_hierarchy_intersecting_with_user_groups(current_user)
      members = GroupMember.where(group: groups).non_invite

      users = super

      users.where(id: members.select(:user_id))
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def issuable_params
      super.merge(group_id: group.id, include_subgroups: true)
    end
  end
end

Gitlab::GroupSearchResults.prepend_mod_with('Gitlab::GroupSearchResults')
