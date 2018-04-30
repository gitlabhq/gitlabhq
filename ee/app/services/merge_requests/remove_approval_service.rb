module MergeRequests
  class RemoveApprovalService < MergeRequests::BaseService
    def execute(merge_request)
      # paranoid protection against running wrong deletes
      return unless merge_request.id && current_user.id

      approval = merge_request.approvals.where(user: current_user)

      currently_approved = merge_request.approved?

      if approval.destroy_all
        merge_request.reset_approval_cache!

        create_note(merge_request)

        if currently_approved
          notification_service.async.unapprove_mr(merge_request, current_user)
          execute_hooks(merge_request, 'unapproved')
        end
      end
    end

    private

    def create_note(merge_request)
      SystemNoteService.unapprove_mr(merge_request, current_user)
    end
  end
end
