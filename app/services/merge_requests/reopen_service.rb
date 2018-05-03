module MergeRequests
  class ReopenService < MergeRequests::BaseService
    def execute(merge_request)
      return merge_request unless can?(current_user, :update_merge_request, merge_request)

      if merge_request.reopen
        create_event(merge_request)
        create_note(merge_request, 'reopened')
        notification_service.async.reopen_mr(merge_request, current_user)
        execute_hooks(merge_request, 'reopen')
        merge_request.reload_diff(current_user)
        merge_request.mark_as_unchecked
        invalidate_cache_counts(merge_request, users: merge_request.assignees)
        merge_request.update_project_counter_caches
      end

      merge_request
    end

    private

    def create_event(merge_request)
      # Making sure MergeRequest::Metrics updates are in sync with
      # Event creation.
      Event.transaction do
        event_service.reopen_mr(merge_request, current_user)
        merge_request_metrics_service(merge_request).reopen
      end
    end
  end
end
