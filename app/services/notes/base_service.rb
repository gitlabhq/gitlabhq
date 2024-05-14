# frozen_string_literal: true

module Notes
  class BaseService < ::BaseService
    include Gitlab::InternalEventsTracking

    def clear_noteable_diffs_cache(note)
      if note.is_a?(DiffNote) &&
          note.start_of_discussion? &&
          note.position.unfolded_diff?(project.repository)
        note.noteable.diffs.clear_cache
      end
    end

    def increment_usage_counter(note)
      if note.noteable_type == 'Commit'
        track_internal_event('create_commit_note', project: project, user: current_user)
      elsif note.noteable_type == 'Snippet'
        track_internal_event('create_snippet_note', project: project, user: current_user)
      else
        Gitlab::UsageDataCounters::NoteCounter.count(:create, note.noteable_type)
      end
    end
  end
end
