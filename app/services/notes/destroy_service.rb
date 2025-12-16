# frozen_string_literal: true

module Notes
  class DestroyService < ::Notes::BaseService
    def execute(note, old_note_body: nil) # rubocop:disable Lint/UnusedMethodArgument -- used in EE override
      TodoService.new.destroy_target(note) do |note|
        note.destroy
      end

      if note.for_merge_request?
        track_note_removal_usage_for_merge_requests(note)

        GraphqlTriggers.merge_request_merge_status_updated(note.noteable) if note.to_be_resolved?
      end

      clear_noteable_diffs_cache(note)

      if note.for_issue?
        track_note_removal_usage_for_issues(note)
        track_note_removal(note.noteable, Gitlab::WorkItems::Instrumentation::EventActions::NOTE_DESTROY)
      end

      if note.for_design?
        track_note_removal_usage_for_design(note)
        track_note_removal(note.noteable.issue, Gitlab::WorkItems::Instrumentation::EventActions::DESIGN_NOTE_DESTROY)
      end

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

    def track_note_removal(work_item, event)
      return unless [
        Gitlab::WorkItems::Instrumentation::EventActions::NOTE_DESTROY,
        Gitlab::WorkItems::Instrumentation::EventActions::DESIGN_NOTE_DESTROY
      ].include?(event)

      ::Gitlab::WorkItems::Instrumentation::TrackingService.new(
        work_item: work_item,
        current_user: current_user,
        event: event
      ).execute
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
