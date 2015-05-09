module Issues
  class ReopenService < Issues::BaseService
    def execute(issue)
      if issue.reopen
        event_service.reopen_issue(issue, current_user)
        create_note(issue)
        notification_service.reopen_issue(issue, current_user)
        execute_hooks(issue, 'reopen')
      end

      issue
    end

    private

    def create_note(issue)
      SystemNoteService.change_status(issue, issue.project, current_user, issue.state, nil)
    end
  end
end
