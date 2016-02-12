module Issues
  class UpdateService < Issues::BaseService
    def execute(issue)
      update(issue)
    end

    def handle_changes(issue, old_labels: [], new_labels: [])
      if has_changes?(issue, options)
        todo_service.mark_pending_todos_as_done(issue, current_user)
      end

      if issue.previous_changes.include?('title') ||
         issue.previous_changes.include?('description')
        todo_service.update_issue(issue, current_user)
      end

      if issue.previous_changes.include?('milestone_id')
        create_milestone_note(issue)
      end

      if issue.previous_changes.include?('assignee_id')
        create_assignee_note(issue)
        notification_service.reassigned_issue(issue, current_user)
        todo_service.reassigned_issue(issue, current_user)
      end

      new_labels = issue.added_labels(old_labels)
      if new_labels.present?
        notification_service.relabeled_issue(issue, new_labels, current_user)
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
