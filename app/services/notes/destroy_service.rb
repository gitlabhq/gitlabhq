# frozen_string_literal: true

module Notes
  class DestroyService < ::Notes::BaseService
    def execute(note, old_note_body: nil) # rubocop:disable Lint/UnusedMethodArgument -- used in EE override
      TodoService.new.destroy_target(note) do |note|
        note.destroy
      end

      clear_noteable_diffs_cache(note)
      track_note_removal_usage_for_issues(note) if note.for_issue?
      track_note_removal_usage_for_merge_requests(note) if note.for_merge_request?
      track_note_removal_usage_for_design(note) if note.for_design?
      track_note_removal_usage_for_wiki(note) if note.for_wiki_page?
    end

    private

    def track_note_removal_usage_for_issues(note)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_comment_removed_action(
        author: note.author,
        project: project
      )
    end

    def track_note_removal_usage_for_merge_requests(note)
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_remove_comment_action(note: note)
    end

    def track_note_removal_usage_for_design(note)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_design_comment_removed_action(
        author: note.author,
        project: project
      )
    end

    def track_note_removal_usage_for_wiki(note)
      track_internal_event(
        'delete_wiki_page_note',
        project: project,
        namespace: note.noteable.namespace,
        user: current_user
      )
    end
  end
end

Notes::DestroyService.prepend_mod_with('Notes::DestroyService')
