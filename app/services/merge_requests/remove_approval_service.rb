# frozen_string_literal: true

module MergeRequests
  class RemoveApprovalService < MergeRequests::BaseService
    # rubocop: disable CodeReuse/ActiveRecord
    def execute(merge_request, skip_updating_state: false, skip_system_note: false, skip_notification: false)
      return unless merge_request.approved_by?(current_user)
      return if merge_request.merged?

      # paranoid protection against running wrong deletes
      return unless merge_request.id && current_user.id

      approval = merge_request.approvals.where(user: current_user)

      trigger_approval_hooks(merge_request, skip_notification) do
        next unless approval.destroy_all # rubocop: disable Cop/DestroyAll

        update_reviewer_state(merge_request, current_user, 'unapproved') unless skip_updating_state
        reset_approvals_cache(merge_request)

        unless skip_system_note
          create_note(merge_request)
          merge_request_activity_counter.track_unapprove_mr_action(user: current_user)
        end

        trigger_merge_request_merge_status_updated(merge_request)
        trigger_merge_request_approval_state_updated(merge_request)
      end

      success
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def reset_approvals_cache(merge_request)
      merge_request.approvals.reset
    end

    def trigger_approval_hooks(merge_request, skip_notification)
      yield

      return if skip_notification

      notification_service.async.unapprove_mr(merge_request, current_user)
      execute_hooks(merge_request, 'unapproved')
    end

    def create_note(merge_request)
      SystemNoteService.unapprove_mr(merge_request, current_user)
    end
  end
end

MergeRequests::RemoveApprovalService.prepend_mod_with('MergeRequests::RemoveApprovalService')
