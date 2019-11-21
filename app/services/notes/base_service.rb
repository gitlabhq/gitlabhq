# frozen_string_literal: true

module Notes
  class BaseService < ::BaseService
    def clear_noteable_diffs_cache(note)
      if note.is_a?(DiffNote) &&
          note.start_of_discussion? &&
          note.position.unfolded_diff?(project.repository)
        note.noteable.diffs.clear_cache
      end
    end

    def increment_usage_counter(note)
      Gitlab::UsageDataCounters::NoteCounter.count(:create, note.noteable_type)
    end
  end
end
