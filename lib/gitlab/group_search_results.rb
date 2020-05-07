# frozen_string_literal: true

module Gitlab
  class GroupSearchResults < SearchResults
    attr_reader :group

    def initialize(current_user, limit_projects, group, query, default_project_filter: false)
      super(current_user, limit_projects, query, default_project_filter: default_project_filter)

      @group = group
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users
      # 1: get all groups the current user has access to
      groups = GroupsFinder.new(current_user).execute.joins(:users)

      # 2: Get the group's whole hierarchy
      group_users = @group.direct_and_indirect_users

      # 3: get all users the current user has access to (->
      # `SearchResults#users`), which also applies the query.
      users = super

      # 4: filter for users that belong to the previously selected groups
      users
        .where(id: group_users.select('id'))
        .where(id: groups.select('members.user_id'))
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def issuable_params
      super.merge(group_id: group.id, include_subgroups: true)
    end
  end
end
