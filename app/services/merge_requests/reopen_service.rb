module MergeRequests
  class ReopenService < MergeRequests::BaseService
    def execute(merge_request)
      return merge_request unless can?(current_user, :update_merge_request, merge_request)

      if merge_request.reopen
        event_service.reopen_mr(merge_request, current_user)
        create_note(merge_request)
        notification_service.reopen_mr(merge_request, current_user)
        execute_hooks(merge_request, 'reopen')
        merge_request.reload_diff(current_user)
        merge_request.mark_as_unchecked
        invalidate_cache_counts(merge_request, users: merge_request.assignees)
      end

      merge_request
    end
  end
end
