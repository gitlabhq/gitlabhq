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
      return if merge_request.merged?

      # Mark the merge request as merged, everything that happens afterwards is
      # executed once
      merge_request.mark_as_merged

      create_event(merge_request)
      todo_service.merge_merge_request(merge_request, current_user)

      merge_request_activity_counter.track_merge_mr_action(user: current_user)

      create_note(merge_request)
      close_issues(merge_request)
      notification_service.merge_mr(merge_request, current_user)
      invalidate_cache_counts(merge_request, users: merge_request.assignees | merge_request.reviewers)
      merge_request.update_project_counter_caches
      delete_non_latest_diffs(merge_request)
      cancel_review_app_jobs!(merge_request)
      cleanup_environments(merge_request)
      cleanup_refs(merge_request)

      execute_hooks(merge_request, 'merge')
    end

    private

    def close_issues(merge_request)
      return unless merge_request.target_branch == project.default_branch

      closed_issues = merge_request.visible_closing_issues_for(current_user)

      closed_issues.each do |issue|
        Issues::CloseService.new(project: project, current_user: current_user).execute(issue, commit: merge_request)
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

MergeRequests::PostMergeService.prepend_mod_with('MergeRequests::PostMergeService')
