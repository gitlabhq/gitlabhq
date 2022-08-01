# frozen_string_literal: true

module MergeRequests
  class ApprovalService < MergeRequests::BaseService
    def execute(merge_request)
      return unless can_be_approved?(merge_request)

      approval = merge_request.approvals.new(user: current_user)

      return success unless save_approval(approval)

      reset_approvals_cache(merge_request)
      merge_request_activity_counter.track_approve_mr_action(user: current_user, merge_request: merge_request)

      # Approval side effects (things not required to be done immediately but
      # should happen after a successful approval) should be done asynchronously
      # utilizing the `Gitlab::EventStore`.
      #
      # Workers can subscribe to the `MergeRequests::ApprovedEvent`.
      if Feature.enabled?(:async_after_approval, project)
        Gitlab::EventStore.publish(
          MergeRequests::ApprovedEvent.new(
            data: { current_user_id: current_user.id, merge_request_id: merge_request.id }
          )
        )
      else
        create_event(merge_request)
      end

      stream_audit_event(merge_request)
      create_approval_note(merge_request)
      mark_pending_todos_as_done(merge_request)
      execute_approval_hooks(merge_request, current_user)
      remove_attention_requested(merge_request)

      success
    end

    private

    def can_be_approved?(merge_request)
      current_user.can?(:approve_merge_request, merge_request)
    end

    def save_approval(approval)
      Approval.safe_ensure_unique do
        approval.save
      end
    end

    def reset_approvals_cache(merge_request)
      merge_request.approvals.reset
    end

    def create_event(merge_request)
      event_service.approve_mr(merge_request, current_user)
    end

    def stream_audit_event(merge_request)
      # Defined in EE
    end

    def create_approval_note(merge_request)
      SystemNoteService.approve_mr(merge_request, current_user)
    end

    def mark_pending_todos_as_done(merge_request)
      todo_service.resolve_todos_for_target(merge_request, current_user)
    end

    def execute_approval_hooks(merge_request, current_user)
      # Only one approval is required for a merge request to be approved
      notification_service.async.approve_mr(merge_request, current_user)

      execute_hooks(merge_request, 'approved')
    end
  end
end

MergeRequests::ApprovalService.prepend_mod_with('MergeRequests::ApprovalService')
