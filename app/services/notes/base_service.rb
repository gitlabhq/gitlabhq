# frozen_string_literal: true

module Notes
  class BaseService < ::BaseService
    def clear_noteable_diffs_cache(note)
      noteable = note.noteable

      if note.is_a?(DiffNote) &&
          note.discussion_first_note? &&
          note.position.unfolded_diff?(project.repository)
        noteable.diffs.clear_cache
      end
    end
  end
end
