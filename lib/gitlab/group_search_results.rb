# frozen_string_literal: true

module Gitlab
  class GroupSearchResults < SearchResults
    def initialize(current_user, limit_projects, group, query, default_project_filter: false, per_page: 20)
      super(current_user, limit_projects, query, default_project_filter: default_project_filter, per_page: per_page)

      @group = group
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users
      super.where(id: @group.users_with_descendants)
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
