module Issues
  class UpdateService < Issues::BaseService
    def execute(issue)
      update(issue)
    end

    def handle_changes(issue, old_labels: [], old_mentioned_users: [])
      if has_changes?(issue, old_labels: old_labels)
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

      if issue.previous_changes.include?('confidential')
        create_confidentiality_note(issue)
      end

      added_labels = issue.labels - old_labels
      if added_labels.present?
        notification_service.relabeled_issue(issue, added_labels, current_user)
      end

      added_mentions = issue.mentioned_users - old_mentioned_users
      if added_mentions.present?
        notification_service.new_mentions_in_issue(issue, added_mentions, current_user)
      end
    end

    def reopen_service
      Issues::ReopenService
    end

    def close_service
      Issues::CloseService
    end

    private

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end
  end
end
