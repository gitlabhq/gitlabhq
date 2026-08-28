# frozen_string_literal: true

module MergeRequests
  class UpdateReviewerStateService < MergeRequests::BaseService
    # unapproved (revoking an approval) and the automatic review_started/unreviewed
    # transitions are excluded: they aren't a review the user is submitting.
    REVIEWER_ASSIGNMENT_STATES = %w[reviewed approved requested_changes].freeze

    def execute(merge_request, state)
      return error("Invalid permissions") unless can?(current_user, :update_merge_request, merge_request)

      # Capture reviewers before mutating so the webhook diff reflects a newly added reviewer.
      old_reviewers_hook_attrs = merge_request.reviewers_hook_attrs if submitted_review?(state)

      reviewer = resolve_reviewer(merge_request, state)

      create_requested_changes(merge_request) if state == 'requested_changes'
      destroy_requested_changes(merge_request) if state == 'approved'
      create_reviewed_system_note(merge_request) if state == 'reviewed'

      if reviewer
        return error("Reviewer has approved") if reviewer.approved? && %w[requested_changes unapproved].exclude?(state)
        return error("Failed to update reviewer") unless reviewer.update(state: state)

        trigger_merge_request_reviewers_updated(merge_request)
        trigger_user_merge_request_updated(merge_request)
        invalidate_cache_counts(merge_request, users: merge_request.assignees)
        current_user.invalidate_merge_request_cache_counts

        execute_submit_review_hooks(merge_request, state, old_reviewers_hook_attrs)

        return success if state != 'requested_changes'

        if merge_request.approved_by?(current_user) && !remove_approval(merge_request, current_user)
          return error("Failed to remove approval")
        end

        success
      else
        error("Reviewer not found")
      end
    end

    private

    def create_requested_changes(merge_request)
      merge_request.create_requested_changes(current_user)

      SystemNoteService.requested_changes(merge_request, current_user)

      trigger_merge_request_merge_status_updated(merge_request)
    end

    def destroy_requested_changes(merge_request)
      merge_request.destroy_requested_changes(current_user)
    end

    def create_reviewed_system_note(merge_request)
      return unless can_leave_reviewed_system_note

      SystemNoteService.reviewed(merge_request, current_user)
    end

    def can_leave_reviewed_system_note
      return true unless current_user.respond_to?(:user_type)

      !current_user.duo_code_review_bot?
    end

    def execute_submit_review_hooks(merge_request, state, old_reviewers_hook_attrs)
      return unless submitted_review?(state)

      execute_hooks(
        merge_request,
        'update',
        old_associations: { reviewers_hook_attrs: old_reviewers_hook_attrs }
      )
    end

    def submitted_review?(state)
      # review_started and unreviewed are automatic transitions (a draft note is created or
      # destroyed, or reviewers are reset on push), not a review the user submitted.
      %w[review_started unreviewed].exclude?(state)
    end

    def resolve_reviewer(merge_request, state)
      if assign_reviewer_on_submission?(merge_request, state)
        merge_request.find_or_create_reviewer(current_user).tap do |reviewer|
          set_first_reviewer_assigned_at_metrics(merge_request) if reviewer&.previously_new_record?
        end
      else
        merge_request.find_reviewer(current_user)
      end
    end

    def assign_reviewer_on_submission?(merge_request, state)
      REVIEWER_ASSIGNMENT_STATES.include?(state) &&
        merge_request.author_id != current_user.id &&
        Feature.enabled?(:assign_reviewer_on_review_submission, merge_request.project) &&
        can_add_reviewer?(merge_request)
    end

    # find_or_create_reviewer writes the row directly, bypassing the reviewer-count
    # validation, so the limit is enforced here. Not atomic with the create, so concurrent
    # submissions can briefly exceed it, which is acceptable for this best-effort assignment.
    def can_add_reviewer?(merge_request)
      if merge_request.allows_multiple_reviewers?
        merge_request.reviewers.size < Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS
      else
        merge_request.reviewers.empty?
      end
    end
  end
end
