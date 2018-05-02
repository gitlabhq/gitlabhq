module Notes
  class ResolveService < ::BaseService
    def execute(note)
      note.resolve!(current_user)

      ::MergeRequests::ResolvedDiscussionNotificationService.new(project, current_user).execute(note.noteable)
    end
  end
end
