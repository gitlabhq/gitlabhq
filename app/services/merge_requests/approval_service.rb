# frozen_string_literal: true

module MergeRequests
  class ApprovalService < MergeRequests::BaseService
    def execute(merge_request)
      unless eligible_for_approval?(merge_request)
        return already_approved_error if merge_request.approved_by?(current_user)

        return ServiceResponse.error(message: 'User is not eligible to approve', reason: :not_eligible)
      end

      if merge_request.merged?
        return ServiceResponse.error(message: 'Merge request is already merged', reason: :merge_request_merged)
      end

      approval = merge_request.approvals.new(
        user: current_user,
        patch_id_sha: patch_id_sha_for(merge_request)
      )

      # A failed save means a concurrent request already created the approval.
      return ServiceResponse.success unless save_approval(approval)

      update_reviewer_state(merge_request, current_user, 'approved')

      reset_approvals_cache(merge_request)

      merge_request_activity_counter.track_approve_mr_action(user: current_user, merge_request: merge_request)

      trigger_merge_request_merge_status_updated(merge_request)
      trigger_merge_request_approval_state_updated(merge_request)

      # Approval side effects (things not required to be done immediately but
      # should happen after a successful approval) should be done asynchronously
      # utilizing the `Gitlab::EventStore`.
      #
      # Workers can subscribe to the `MergeRequests::ApprovedEvent`.
      Gitlab::EventStore.publish(
        MergeRequests::ApprovedEvent.new(
          data: { current_user_id: current_user.id, merge_request_id: merge_request.id,
                  approved_at: approval.created_at.iso8601 }
        )
      )

      # CloudEvent consumed by AI flow trigger workers
      Gitlab::EventStore.publish(
        MergeRequests::ApprovedCloudEvent.build(
          merge_request: merge_request,
          current_user: current_user,
          approval: approval
        )
      )

      ServiceResponse.success
    end

    private

    def already_approved_error
      ServiceResponse.error(message: 'Merge request is already approved by the user', reason: :already_approved)
    end

    def eligible_for_approval?(merge_request)
      merge_request.eligible_for_approval_by?(current_user)
    end

    def patch_id_sha_for(merge_request)
      unless Feature.enabled?(:patch_id_sha_fallback_when_diff_missing, merge_request.target_project)
        return merge_request.current_patch_id_sha
      end

      sha = params[:sha]

      # The API checked `sha` against the diff head before calling us, but a push can land in
      # between and swap the diff. Recording that newer diff's patch ID would credit the approver
      # with a version they never saw, so only use the diff when it is still for `sha`.
      if sha.blank? || merge_request.merge_request_diff.head_commit_sha == sha
        patch_id_sha = merge_request.current_patch_id_sha
        return patch_id_sha if patch_id_sha.present?
      end

      merge_request.patch_id_sha_for_head(sha)
    end

    def save_approval(approval)
      Approval.safe_ensure_unique do
        approval.save
      end
    end

    def reset_approvals_cache(merge_request)
      merge_request.approvals.reset
    end
  end
end

MergeRequests::ApprovalService.prepend_mod_with('MergeRequests::ApprovalService')
