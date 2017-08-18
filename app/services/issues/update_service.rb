module Issues
  class UpdateService < Issues::BaseService
    include SpamCheckService

    def execute(issue)
      handle_move_between_iids(issue)
      filter_spam_check_params
      change_issue_duplicate(issue)
      update(issue)
    end

    def before_update(issue)
      spam_check(issue, current_user)
    end

    def handle_changes(issue, options)
      old_labels = options[:old_labels] || []
      old_mentioned_users = options[:old_mentioned_users] || []
      old_assignees = options[:old_assignees] || []

      if has_changes?(issue, old_labels: old_labels, old_assignees: old_assignees)
        todo_service.mark_pending_todos_as_done(issue, current_user)
      end

      if issue.previous_changes.include?('title') ||
          issue.previous_changes.include?('description')
        todo_service.update_issue(issue, current_user, old_mentioned_users)
      end

      if issue.previous_changes.include?('milestone_id')
        create_milestone_note(issue)
      end

      if issue.assignees != old_assignees
        create_assignee_note(issue, old_assignees)
        notification_service.reassigned_issue(issue, current_user, old_assignees)
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

    def handle_move_between_iids(issue)
      return unless params[:move_between_iids]

      after_iid, before_iid = params.delete(:move_between_iids)

      issue_before = get_issue_if_allowed(issue.project, before_iid) if before_iid
      issue_after = get_issue_if_allowed(issue.project, after_iid) if after_iid

      issue.move_between(issue_before, issue_after)
    end

    def change_issue_duplicate(issue)
      canonical_issue_id = params.delete(:canonical_issue_id)
      canonical_issue = IssuesFinder.new(current_user).find_by(id: canonical_issue_id)

      if canonical_issue
        Issues::DuplicateService.new(project, current_user).execute(issue, canonical_issue)
      end
    end

    private

    def get_issue_if_allowed(project, iid)
      issue = project.issues.find_by(iid: iid)
      issue if can?(current_user, :update_issue, issue)
    end

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end
  end
end
