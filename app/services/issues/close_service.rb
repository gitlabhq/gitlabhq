module Issues
  class CloseService < Issues::BaseService
    def execute(issue, commit = nil)
      if issue.close
        notification_service.close_issue(issue, current_user)
        event_service.close_issue(issue, current_user)
        create_note(issue, commit)
        execute_hooks(issue, 'close')
      end

      issue
    end

    private

    def create_note(issue, current_commit)
      Note.create_status_change_note(issue, issue.project, current_user, issue.state, current_commit)
    end
  end
end
