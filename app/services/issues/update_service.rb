# frozen_string_literal: true

module Issues
  class UpdateService < Issues::BaseService
    # NOTE: For Issues::UpdateService, we default the spam_params to nil, because spam_checking is not
    # necessary in many cases, and we don't want to require every caller to explicitly pass it as nil
    # to disable spam checking.
    def initialize(container:, current_user: nil, params: {}, spam_params: nil)
      super(container: container, current_user: current_user, params: params)
      @spam_params = spam_params
    end

    def execute(issue)
      handle_move_between_ids(issue)

      change_issue_duplicate(issue)
      move_issue_to_new_project(issue) || clone_issue(issue) || update_task_event(issue) || update(issue)
    end

    def update(issue)
      create_merge_request_from_quick_action

      super
    end

    def before_update(issue, skip_spam_check: false)
      change_work_item_type(issue)

      return if skip_spam_check

      Spam::SpamActionService.new(
        spammable: issue,
        spam_params: spam_params,
        user: current_user,
        action: :update
      ).execute
    end

    def change_work_item_type(issue)
      return unless issue.changed_attributes['issue_type']

      type_id = find_work_item_type_id(issue.issue_type)

      issue.work_item_type_id = type_id
    end

    def handle_changes(issue, options)
      super
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])
      old_severity = old_associations[:severity]

      if has_changes?(issue, old_labels: old_labels, old_assignees: old_assignees)
        todo_service.resolve_todos_for_target(issue, current_user)
      end

      if issue.previous_changes.include?('title') ||
          issue.previous_changes.include?('description')
        todo_service.update_issue(issue, current_user, old_mentioned_users)
      end

      handle_assignee_changes(issue, old_assignees)
      handle_confidential_change(issue)
      handle_added_labels(issue, old_labels)
      handle_added_mentions(issue, old_mentioned_users)
      handle_severity_change(issue, old_severity)
      handle_escalation_status_change(issue)
      handle_issue_type_change(issue)
      handle_date_changes(issue)
    end

    def handle_assignee_changes(issue, old_assignees)
      return if issue.assignees == old_assignees

      create_assignee_note(issue, old_assignees)
      Gitlab::ResourceEvents::AssignmentEventRecorder.new(parent: issue, old_assignees: old_assignees).record
      notification_service.async.reassigned_issue(issue, current_user, old_assignees)
      todo_service.reassigned_assignable(issue, current_user, old_assignees)
      track_incident_action(current_user, issue, :incident_assigned)

      GraphqlTriggers.issuable_assignees_updated(issue)
    end

    def handle_task_changes(issuable)
      todo_service.resolve_todos_for_target(issuable, current_user)
      todo_service.update_issue(issuable, current_user)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def change_issue_duplicate(issue)
      canonical_issue_id = params.delete(:canonical_issue_id)
      return unless canonical_issue_id

      canonical_issue = IssuesFinder.new(current_user).find_by(id: canonical_issue_id)

      if canonical_issue
        Issues::DuplicateService.new(container: project, current_user: current_user).execute(issue, canonical_issue)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def move_issue_to_new_project(issue)
      target_project = params.delete(:target_project)

      return unless target_project &&
          issue.can_move?(current_user, target_project) &&
          target_project != issue.project

      update(issue)
      Issues::MoveService.new(container: project, current_user: current_user).execute(issue, target_project)
    end

    private

    attr_reader :spam_params

    def handle_date_changes(issue)
      return unless issue.previous_changes.slice('due_date', 'start_date').any?

      GraphqlTriggers.issuable_dates_updated(issue)
    end

    def clone_issue(issue)
      target_project = params.delete(:target_clone_project)
      with_notes = params.delete(:clone_with_notes)

      return unless target_project &&
        issue.can_clone?(current_user, target_project)

      # we've pre-empted this from running in #execute, so let's go ahead and update the Issue now.
      update(issue)
      Issues::CloneService.new(container: project, current_user: current_user).execute(issue, target_project, with_notes: with_notes)
    end

    def create_merge_request_from_quick_action
      create_merge_request_params = params.delete(:create_merge_request)
      return unless create_merge_request_params

      MergeRequests::CreateFromIssueService.new(project: project, current_user: current_user, mr_params: create_merge_request_params).execute
    end

    def handle_confidential_change(issue)
      if issue.previous_changes.include?('confidential')
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, issue.id) if issue.confidential?
        create_confidentiality_note(issue)
        track_incident_action(current_user, issue, :incident_change_confidential)
      end
    end

    def handle_added_labels(issue, old_labels)
      added_labels = issue.labels - old_labels

      if added_labels.present?
        notification_service.async.relabeled_issue(issue, added_labels, current_user)
      end
    end

    def handle_added_mentions(issue, old_mentioned_users)
      added_mentions = issue.mentioned_users(current_user) - old_mentioned_users

      if added_mentions.present?
        notification_service.async.new_mentions_in_issue(issue, added_mentions, current_user)
      end
    end

    def handle_severity_change(issue, old_severity)
      return unless old_severity && issue.severity != old_severity

      ::IncidentManagement::AddSeveritySystemNoteWorker.perform_async(issue.id, current_user.id)
    end

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end

    def handle_issue_type_change(issue)
      return unless issue.previous_changes.include?('issue_type')

      do_handle_issue_type_change(issue)
    end

    def do_handle_issue_type_change(issue)
      SystemNoteService.change_issue_type(issue, current_user, issue.issue_type_before_last_save)

      ::IncidentManagement::IssuableEscalationStatuses::CreateService.new(issue).execute if issue.supports_escalation?
    end
  end
end

Issues::UpdateService.prepend_mod_with('Issues::UpdateService')
