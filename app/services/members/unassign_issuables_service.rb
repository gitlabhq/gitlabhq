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

      unassign_from_issues(project_ids)
      unassign_from_merge_requests(project_ids)

      user.invalidate_cache_counts
    end

    private

    def unassign_from_issues(project_ids)
      user.issue_assignees.on_issues(Issue.in_projects(project_ids)).select(:issue_id).each do |assignee|
        issue = Issue.find(assignee.issue_id)

        Issues::UpdateService.new(
          container: issue.project,
          current_user: user,
          params: { assignee_ids: new_assignee_ids(issue) }
        ).execute(issue)
      end
    end

    def unassign_from_merge_requests(project_ids)
      user.merge_request_assignees.in_projects(project_ids).select(:merge_request_id).each do |assignee|
        merge_request = MergeRequest.find(assignee.merge_request_id)

        ::MergeRequests::UpdateAssigneesService.new(
          project: merge_request.project,
          current_user: user,
          params: { assignee_ids: new_assignee_ids(merge_request), skip_authorization: true }
        ).execute(merge_request)
      end
    end

    def new_assignee_ids(issuable)
      issuable.assignees.map(&:id) - [user.id]
    end
  end
end
