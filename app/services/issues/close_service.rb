module Issues
  class CloseService < Issues::BaseService
    def execute(issue, commit = nil)
      if project.default_issues_tracker? && issue.close
        event_service.close_issue(issue, current_user)
        create_note(issue, commit)
        notification_service.close_issue(issue, current_user)
        execute_hooks(issue, 'close')
      end

      issue
    end

    private

    def create_note(issue, current_commit)
      SystemNoteService.change_status(issue, issue.project, current_user, issue.state, current_commit)
    end
  end
end
