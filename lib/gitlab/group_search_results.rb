# frozen_string_literal: true

module Gitlab
  class GroupSearchResults < SearchResults
    def initialize(current_user, limit_projects, group, query, default_project_filter: false, per_page: 20)
      super(current_user, limit_projects, query, default_project_filter: default_project_filter, per_page: per_page)

      @group = group
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users
      # 1: get all groups the current user has access to
      groups = GroupsFinder.new(current_user).execute.joins(:users)

      # 2: get all users the current user has access to (-> `SearchResults#users`)
      users = super

      # 3: filter for users that belong to the previously selected groups
      users.where(id: groups.select('members.user_id'))
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
