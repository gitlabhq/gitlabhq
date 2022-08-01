# frozen_string_literal: true

module MergeRequests
  class CreateApprovalEventService < MergeRequests::BaseService
    def execute(merge_request)
      event_service.approve_mr(merge_request, current_user)
    end
  end
end

MergeRequests::CreateApprovalEventService.prepend_mod
