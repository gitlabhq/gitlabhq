# frozen_string_literal: true

module Gitlab
  class GroupSearchResults < SearchResults
    attr_reader :group

    def initialize(current_user, query, limit_projects = nil, group:, default_project_filter: false, order_by: nil, sort: nil, filters: {})
      @group = group

      super(current_user, query, limit_projects, default_project_filter: default_project_filter, order_by: order_by, sort: sort, filters: filters)
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
