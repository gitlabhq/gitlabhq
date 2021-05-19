# frozen_string_literal: true

module MergeRequests
  class ApprovalService < MergeRequests::BaseService
    def execute(merge_request)
      return unless can_be_approved?(merge_request)

      approval = merge_request.approvals.new(user: current_user)

      return success unless save_approval(approval)

      reset_approvals_cache(merge_request)
      create_event(merge_request)
      create_approval_note(merge_request)
      mark_pending_todos_as_done(merge_request)
      execute_approval_hooks(merge_request, current_user)
      merge_request_activity_counter.track_approve_mr_action(user: current_user)

      success
    end

    private

    def can_be_approved?(merge_request)
      current_user.can?(:approve_merge_request, merge_request)
    end

    def reset_approvals_cache(merge_request)
      merge_request.approvals.reset
    end

    def execute_approval_hooks(merge_request, current_user)
      # Only one approval is required for a merge request to be approved
      execute_hooks(merge_request, 'approved')
    end

    def save_approval(approval)
      Approval.safe_ensure_unique do
        approval.save
      end
    end

    def create_approval_note(merge_request)
      SystemNoteService.approve_mr(merge_request, current_user)
    end

    def mark_pending_todos_as_done(merge_request)
      todo_service.resolve_todos_for_target(merge_request, current_user)
    end

    def create_event(merge_request)
      event_service.approve_mr(merge_request, current_user)
    end
  end
end

MergeRequests::ApprovalService.prepend_mod_with('MergeRequests::ApprovalService')
