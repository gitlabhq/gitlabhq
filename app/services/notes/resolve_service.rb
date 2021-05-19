# frozen_string_literal: true

module Notes
  class ResolveService < ::BaseService
    def execute(note)
      note.resolve!(current_user)

      ::MergeRequests::ResolvedDiscussionNotificationService.new(project: project, current_user: current_user).execute(note.noteable)
    end
  end
end
