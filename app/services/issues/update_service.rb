# frozen_string_literal: true

module Issues
  class UpdateService < Issues::BaseService
    include SpamCheckService

    def execute(issue)
      handle_move_between_ids(issue)
      filter_spam_check_params
      change_issue_duplicate(issue)
      move_issue_to_new_project(issue) || update_task_event(issue) || update(issue)
    end

    def update(issue)
      create_merge_request_from_quick_action

      super
    end

    def before_update(issue, skip_spam_check: false)
      spam_check(issue, current_user) unless skip_spam_check
    end

    def handle_changes(issue, options)
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])

      if has_changes?(issue, old_labels: old_labels, old_assignees: old_assignees)
        todo_service.mark_pending_todos_as_done(issue, current_user)
      end

      if issue.previous_changes.include?('title') ||
          issue.previous_changes.include?('description')
        todo_service.update_issue(issue, current_user, old_mentioned_users)
      end

      if issue.assignees != old_assignees
        create_assignee_note(issue, old_assignees)
        notification_service.async.reassigned_issue(issue, current_user, old_assignees)
        todo_service.reassigned_issuable(issue, current_user, old_assignees)
      end

      if issue.previous_changes.include?('confidential')
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, issue.id) if issue.confidential?
        create_confidentiality_note(issue)
      end

      added_labels = issue.labels - old_labels

      if added_labels.present?
        notification_service.async.relabeled_issue(issue, added_labels, current_user)
      end

      handle_milestone_change(issue)

      added_mentions = issue.mentioned_users(current_user) - old_mentioned_users

      if added_mentions.present?
        notification_service.async.new_mentions_in_issue(issue, added_mentions, current_user)
      end
    end

    def handle_task_changes(issuable)
      todo_service.mark_pending_todos_as_done(issuable, current_user)
      todo_service.update_issue(issuable, current_user)
    end

    def handle_move_between_ids(issue)
      return unless params[:move_between_ids]

      after_id, before_id = params.delete(:move_between_ids)
      board_group_id = params.delete(:board_group_id)

      issue_before = get_issue_if_allowed(before_id, board_group_id)
      issue_after = get_issue_if_allowed(after_id, board_group_id)
      raise ActiveRecord::RecordNotFound unless issue_before || issue_after

      issue.move_between(issue_before, issue_after)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def change_issue_duplicate(issue)
      canonical_issue_id = params.delete(:canonical_issue_id)
      return unless canonical_issue_id

      canonical_issue = IssuesFinder.new(current_user).find_by(id: canonical_issue_id)

      if canonical_issue
        Issues::DuplicateService.new(project, current_user).execute(issue, canonical_issue)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def move_issue_to_new_project(issue)
      target_project = params.delete(:target_project)

      return unless target_project &&
          issue.can_move?(current_user, target_project) &&
          target_project != issue.project

      update(issue)
      Issues::MoveService.new(project, current_user).execute(issue, target_project)
    end

    private

    def create_merge_request_from_quick_action
      create_merge_request_params = params.delete(:create_merge_request)
      return unless create_merge_request_params

      MergeRequests::CreateFromIssueService.new(project, current_user, create_merge_request_params).execute
    end

    def handle_milestone_change(issue)
      return if skip_milestone_email

      return unless issue.previous_changes.include?('milestone_id')

      if issue.milestone.nil?
        notification_service.async.removed_milestone_issue(issue, current_user)
      else
        notification_service.async.changed_milestone_issue(issue, issue.milestone, current_user)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def get_issue_if_allowed(id, board_group_id = nil)
      return unless id

      issue =
        if board_group_id
          IssuesFinder.new(current_user, group_id: board_group_id, include_subgroups: true).find_by(id: id)
        else
          project.issues.find(id)
        end

      issue if can?(current_user, :update_issue, issue)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end
  end
end

Issues::UpdateService.prepend_if_ee('EE::Issues::UpdateService')
