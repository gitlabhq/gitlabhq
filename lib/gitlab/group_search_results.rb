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
      # get all groups the current user has access to
      # ignore order inherited from GroupsFinder to improve performance
      current_user_groups = GroupsFinder.new(current_user).execute.unscope(:order)

      # the hierarchy of the current group
      group_groups = @group.self_and_hierarchy.unscope(:order)

      # the groups where the above hierarchies intersect
      intersect_groups = group_groups.where(id: current_user_groups)

      # members of @group hierarchy where the user has access to the groups
      members = GroupMember.where(group: intersect_groups).non_invite

      # get all users the current user has access to (-> `SearchResults#users`), which also applies the query
      users = super

      #  filter users that belong to the previously selected groups
      users.where(id: members.select(:user_id))
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def issuable_params
      super.merge(group_id: group.id, include_subgroups: true)
    end
  end
end

Gitlab::GroupSearchResults.prepend_mod_with('Gitlab::GroupSearchResults')
