module MergeRequests
  class CloseService < MergeRequests::BaseService
    def execute(merge_request, commit = nil)
      # If we close MergeRequest we want to ignore validation
      # so we can close broken one (Ex. fork project removed)
      merge_request.allow_broken = true

      if merge_request.close
        event_service.close_mr(merge_request, current_user)
        notification_service.close_mr(merge_request, current_user)
        create_note(merge_request)
        execute_hooks(merge_request)
      end

      merge_request
    end
  end
end
