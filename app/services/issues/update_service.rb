module Issues
  class UpdateService < Issues::BaseService
    def execute(issue)
      update(issue)
    end

    def handle_changes(issue)
      if issue.previous_changes.include?('milestone_id')
        create_milestone_note(issue)
      end

      if issue.previous_changes.include?('assignee_id')
        create_assignee_note(issue)
        notification_service.reassigned_issue(issue, current_user)
      end
    end

    def reopen_service
      Issues::ReopenService
    end

    def close_service
      Issues::CloseService
    end
  end
end
