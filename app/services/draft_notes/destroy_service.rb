# frozen_string_literal: true

module DraftNotes
  class DestroyService < DraftNotes::BaseService
    # If no `draft` is given it fallsback to all
    # draft notes of the given merge request and user.
    def execute(draft = nil)
      drafts = draft || draft_notes

      clear_highlight_diffs_cache(Array.wrap(drafts))

      drafts.is_a?(DraftNote) ? drafts.destroy! : drafts.delete_all

      after_execute
    end

    private

    def after_execute
      # Update reviewer state to `UNREVIEWED` when a new review was deleted
      return unless draft_notes.empty?

      ::MergeRequests::UpdateReviewerStateService
        .new(project: merge_request.project, current_user: current_user)
        .execute(merge_request, 'unreviewed')
    end

    def clear_highlight_diffs_cache(drafts)
      merge_request.diffs.clear_cache if unfolded_drafts?(drafts)
    end

    def unfolded_drafts?(drafts)
      drafts.any? { |draft| draft.diff_file&.unfolded? }
    end
  end
end
