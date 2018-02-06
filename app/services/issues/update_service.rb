module Issues
  class UpdateService < Issues::BaseService
    include SpamCheckService

    def execute(issue)
      handle_move_between_ids(issue)
      filter_spam_check_params
      change_issue_duplicate(issue)
      move_issue_to_new_project(issue) || update(issue)
    end

    def before_update(issue)
      spam_check(issue, current_user)
    end

    def after_update(issue)
      schedule_due_date_email(issue)
    end

    def handle_changes(issue, options)
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])

      if has_changes?(issue, old_labels: old_labels, old_assignees: old_assignees)
        todo_service.mark_pending_todos_as_done(issue, current_user)
      end

      # TODO: If due date doesn't change, don't bother updating the due date
      # email worker

      if issue.previous_changes.include?('title') ||
          issue.previous_changes.include?('description')
        todo_service.update_issue(issue, current_user, old_mentioned_users)
      end

      if issue.assignees != old_assignees
        create_assignee_note(issue, old_assignees)
        notification_service.reassigned_issue(issue, current_user, old_assignees)
        todo_service.reassigned_issue(issue, current_user, old_assignees)
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

    def handle_move_between_ids(issue)
      return unless params[:move_between_ids]

      after_id, before_id = params.delete(:move_between_ids)

      issue_before = get_issue_if_allowed(issue.project, before_id) if before_id
      issue_after = get_issue_if_allowed(issue.project, after_id) if after_id

      issue.move_between(issue_before, issue_after)
    end

    def change_issue_duplicate(issue)
      canonical_issue_id = params.delete(:canonical_issue_id)
      canonical_issue = IssuesFinder.new(current_user).find_by(id: canonical_issue_id)

      if canonical_issue
        Issues::DuplicateService.new(project, current_user).execute(issue, canonical_issue)
      end
    end

    def move_issue_to_new_project(issue)
      target_project = params.delete(:target_project)

      return unless target_project &&
          issue.can_move?(current_user, target_project) &&
          target_project != issue.project

      update(issue)
      Issues::MoveService.new(project, current_user).execute(issue, target_project)
    end

    private

    def get_issue_if_allowed(project, id)
      issue = project.issues.find(id)
      issue if can?(current_user, :update_issue, issue)
    end

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end
  end
end
