module MergeRequests
  class ReopenService < MergeRequests::BaseService
    def execute(merge_request)
      if merge_request.reopen
        event_service.reopen_mr(merge_request, current_user)
        notification_service.reopen_mr(merge_request, current_user)
        create_note(merge_request)
        execute_hooks(merge_request)
        merge_request.reload_code
        merge_request.mark_as_unchecked
      end

      merge_request
    end
  end
end
