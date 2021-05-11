# frozen_string_literal: true

module Notes
  class DestroyService < ::Notes::BaseService
    def execute(note)
      TodoService.new.destroy_target(note) do |note|
        note.destroy
      end

      clear_noteable_diffs_cache(note)
      track_note_removal_usage_for_issues(note) if note.for_issue?
      track_note_removal_usage_for_merge_requests(note) if note.for_merge_request?
    end

    private

    def track_note_removal_usage_for_issues(note)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_comment_removed_action(author: note.author)
    end

    def track_note_removal_usage_for_merge_requests(note)
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_remove_comment_action(note: note)
    end
  end
end

Notes::DestroyService.prepend_mod_with('Notes::DestroyService')
