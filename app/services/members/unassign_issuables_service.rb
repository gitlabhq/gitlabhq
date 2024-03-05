# frozen_string_literal: true

module Members
  class UnassignIssuablesService
    attr_reader :user, :entity, :requesting_user

    # @param [User] user user whose membership is being deleted from entity
    # @param [Group, Project] entity
    # @param [User] requesting_user user who initiated the membership deletion of `user`
    def initialize(user, entity, requesting_user)
      @user = user
      @requesting_user = requesting_user
      @entity = entity
    end

    def execute
      if Feature.enabled?(:new_unassignment_service) && !requesting_user
        raise ArgumentError, 'requesting_user must be given'
      end

      return unless entity && user

      project_ids = entity.is_a?(Group) ? entity.all_projects.select(:id) : [entity.id]

      if Feature.enabled?(:new_unassignment_service)
        unassign_from_issues(project_ids)
        unassign_from_merge_requests(project_ids)
      else
        user.issue_assignees.on_issues(Issue.in_projects(project_ids).select(:id)).delete_all
        user.merge_request_assignees.in_projects(project_ids).delete_all
      end

      user.invalidate_cache_counts
    end

    private

    def unassign_from_issues(project_ids)
      IssueAssignee
        .for_assignee(user)
        .in_projects(project_ids)
        .each_batch(column: :issue_id) do |assignees|
          assignees.each do |assignee|
            issue = assignee.issue
            next unless issue

            Issues::UpdateService.new(
              container: issue.project,
              current_user: requesting_user,
              params: { assignee_ids: new_assignee_ids(issue) }
            ).execute(issue)

          rescue ActiveRecord::StaleObjectError
            # It's possible for `issue` to be stale (removed) by the time Issues::UpdateService attempts to update it.
            # Continue to the next item.
          end
        end
    end

    def unassign_from_merge_requests(project_ids)
      MergeRequestAssignee
        .for_assignee(user)
        .in_projects(project_ids)
        .each_batch(column: :merge_request_id) do |assignees|
          assignees.each do |assignee|
            merge_request = assignee.merge_request
            next unless merge_request

            ::MergeRequests::UpdateAssigneesService.new(
              project: merge_request.project,
              current_user: requesting_user,
              params: { assignee_ids: new_assignee_ids(merge_request) }
            ).execute(merge_request)

          rescue ActiveRecord::StaleObjectError
            # It's possible for `merge_request` to be stale (removed) by the time
            # MergeRequests::UpdateAssigneesService attempts to update it. Continue to the next item.
          end
        end
    end

    def new_assignee_ids(issuable)
      issuable.assignees.map(&:id) - [user.id]
    end
  end
end
