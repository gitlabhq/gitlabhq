module Issues
  class UpdateService < Issues::BaseService
    def execute(issue)
      handle_move_between_iids(issue)
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

    def handle_move_between_iids(issue)
      if move_between_iids = params.delete(:move_between_iids)
        before_iid, after_iid = move_between_iids

        issue_before = nil
        if before_iid
          issue_before = issue.project.issues.find_by(iid: before_iid)
          issue_before = nil unless can?(current_user, :update_issue, issue_before)
        end

        issue_after = nil
        if after_iid
          issue_after = issue.project.issues.find_by(iid: after_iid)
          issue_after = nil unless can?(current_user, :update_issue, issue_after)
        end

        issue.move_between(issue_before, issue_after)
      end
    end

    private

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end
  end
end
