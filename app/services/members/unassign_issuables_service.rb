# frozen_string_literal: true

module Members
  class UnassignIssuablesService
    attr_reader :user, :entity

    def initialize(user, entity)
      @user = user
      @entity = entity
    end

    def execute
      return unless entity && user

      project_ids = entity.is_a?(Group) ? entity.all_projects.select(:id) : [entity.id]

      user.issue_assignees.on_issues(Issue.in_projects(project_ids).select(:id)).delete_all
      user.merge_request_assignees.in_projects(project_ids).delete_all

      user.invalidate_cache_counts
    end
  end
end
