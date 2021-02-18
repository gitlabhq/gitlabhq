# frozen_string_literal: true

module MergeRequests
  # PostMergeService class
  #
  # Mark existing merge request as merged
  # and execute all hooks and notifications
  #
  class PostMergeService < MergeRequests::BaseService
    include RemovesRefs

    MAX_RETARGET_MERGE_REQUESTS = 4

    def execute(merge_request)
      merge_request.mark_as_merged
      close_issues(merge_request)
      todo_service.merge_merge_request(merge_request, current_user)
      create_event(merge_request)
      create_note(merge_request)
      merge_request_activity_counter.track_merge_mr_action(user: current_user)
      notification_service.merge_mr(merge_request, current_user)
      execute_hooks(merge_request, 'merge')
      retarget_chain_merge_requests(merge_request)
      invalidate_cache_counts(merge_request, users: merge_request.assignees | merge_request.reviewers)
      merge_request.update_project_counter_caches
      delete_non_latest_diffs(merge_request)
      cancel_review_app_jobs!(merge_request)
      cleanup_environments(merge_request)
      cleanup_refs(merge_request)
    end

    private

    def retarget_chain_merge_requests(merge_request)
      return unless Feature.enabled?(:retarget_merge_requests, merge_request.target_project)

      # we can only retarget MRs that are targeting the same project
      # and have a remove source branch set
      return unless merge_request.for_same_project? && merge_request.remove_source_branch?

      # find another merge requests that
      # - as a target have a current source project and branch
      other_merge_requests = merge_request.source_project
        .merge_requests
        .opened
        .by_target_branch(merge_request.source_branch)
        .preload_source_project
        .at_most(MAX_RETARGET_MERGE_REQUESTS)

      other_merge_requests.find_each do |other_merge_request|
        # Update only MRs on projects that we have access to
        next unless can?(current_user, :update_merge_request, other_merge_request.source_project)

        ::MergeRequests::UpdateService
          .new(other_merge_request.source_project, current_user,
            target_branch: merge_request.target_branch,
            target_branch_was_deleted: true)
          .execute(other_merge_request)
      end
    end

    def close_issues(merge_request)
      return unless merge_request.target_branch == project.default_branch

      closed_issues = merge_request.visible_closing_issues_for(current_user)

      closed_issues.each do |issue|
        Issues::CloseService.new(project, current_user).execute(issue, commit: merge_request)
      end
    end

    def delete_non_latest_diffs(merge_request)
      DeleteNonLatestDiffsService.new(merge_request).execute
    end

    def create_merge_event(merge_request, current_user)
      EventCreateService.new.merge_mr(merge_request, current_user)
    end

    def create_event(merge_request)
      # Making sure MergeRequest::Metrics updates are in sync with
      # Event creation.
      Event.transaction do
        merge_event = create_merge_event(merge_request, current_user)
        merge_request_metrics_service(merge_request).merge(merge_event)
      end
    end
  end
end

MergeRequests::PostMergeService.prepend_if_ee('EE::MergeRequests::PostMergeService')
