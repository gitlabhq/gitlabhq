# frozen_string_literal: true

module Notes
  class ResolveService < ::BaseService
    def execute(note)
      # Already resolved: no-op to avoid re-posting the "resolved all threads" note.
      return if note.resolved?

      note.resolve!(current_user)

      case note.noteable
      when MergeRequest
        ::MergeRequests::ResolvedDiscussionNotificationService
          .new(project: project, current_user: current_user)
          .execute(note.noteable)
      end
    end
  end
end
