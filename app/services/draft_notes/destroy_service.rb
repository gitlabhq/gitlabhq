# frozen_string_literal: true

module DraftNotes
  class DestroyService < DraftNotes::BaseService
    # If no `draft` is given it fallsback to all
    # draft notes of the given merge request and user.
    def execute(draft = nil)
      drafts = draft || draft_notes

      clear_highlight_diffs_cache(Array.wrap(drafts))

      drafts.is_a?(DraftNote) ? drafts.destroy! : drafts.delete_all
    end

    private

    def clear_highlight_diffs_cache(drafts)
      if drafts.any? { |draft| draft.diff_file&.unfolded? }
        merge_request.diffs.clear_cache
      end
    end
  end
end
