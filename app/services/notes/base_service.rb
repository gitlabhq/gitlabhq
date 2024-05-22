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
      case note.noteable_type
      when 'Commit'
        track_internal_event('create_commit_note', project: project, user: current_user)
      when 'Snippet'
        track_internal_event('create_snippet_note', project: project, user: current_user)
      when 'MergeRequest'
        track_internal_event('create_merge_request_note', project: project, user: current_user)
      end
    end
  end
end
