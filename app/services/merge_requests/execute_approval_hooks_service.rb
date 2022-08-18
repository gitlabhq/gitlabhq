# frozen_string_literal: true

module MergeRequests
  class ExecuteApprovalHooksService < MergeRequests::BaseService
    def execute(merge_request)
      # Only one approval is required for a merge request to be approved
      notification_service.async.approve_mr(merge_request, current_user)
      execute_hooks(merge_request, 'approved')
    end
  end
end

MergeRequests::ExecuteApprovalHooksService.prepend_mod
