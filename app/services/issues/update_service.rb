# frozen_string_literal: true

module Issues
  class UpdateService < Issues::BaseService
    # NOTE: For Issues::UpdateService, we default perform_spam_check to false, because spam_checking is not
    # necessary in many cases, and we don't want to require every caller to explicitly pass it
    # to disable spam checking.
    def initialize(container:, current_user: nil, params: {}, perform_spam_check: false)
      super(container: container, current_user: current_user, params: params)
      @perform_spam_check = perform_spam_check
    end

    def execute(issue)
      handle_move_between_ids(issue)

      change_issue_duplicate(issue)
      move_issue_to_new_container(issue) || clone_issue(issue) || update_task_event(issue) || update(issue)
    end

    def update(issue)
      create_merge_request_from_quick_action

      super
    end

    def before_update(issue, skip_spam_check: false)
      change_work_item_type(issue)

      return if skip_spam_check || !perform_spam_check

      issue.check_for_spam(user: current_user, action: :update)
    end

    def change_work_item_type(issue)
      return unless params[:issue_type].present?

      type_id = find_work_item_type_id(params[:issue_type])

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

    def change_issue_duplicate(issue)
      canonical_issue_id = params.delete(:canonical_issue_id)
      return unless canonical_issue_id

      canonical_issue = Issue.find_by_id(canonical_issue_id)

      if canonical_issue
        Issues::DuplicateService.new(container: project, current_user: current_user).execute(issue, canonical_issue)
      end
    end

    def move_issue_to_new_container(issue)
      target_container = params.delete(:target_container)

      return unless target_container &&
        issue.can_move?(current_user, target_container) &&
        !move_to_same_container?(issue, target_container)

      update(issue)

      if Feature.enabled?(:work_item_move_and_clone, container)
        move_service_container = target_container.is_a?(Project) ? target_container.project_namespace : target_container
        ::WorkItems::DataSync::MoveService.new(
          work_item: issue, current_user: current_user, target_namespace: move_service_container
        ).execute[:work_item]
      else
        ::Issues::MoveService.new(
          container: project, current_user: current_user
        ).execute(issue, target_container)
      end
    end

    private

    attr_reader :perform_spam_check

    override :after_update
    def after_update(issue, old_associations)
      super

      GraphqlTriggers.work_item_updated(issue)
      publish_event(issue, old_associations)
    end

    def publish_event(work_item, old_associations)
      event = WorkItems::WorkItemUpdatedEvent.new(data: {
        id: work_item.id,
        namespace_id: work_item.namespace_id,
        previous_work_item_parent_id: old_associations[:work_item_parent_id],
        updated_attributes: work_item.previous_changes&.keys&.map(&:to_s),
        updated_widgets: @widget_params&.compact_blank&.keys&.map(&:to_s)
      }.tap(&:compact_blank!))

      work_item.run_after_commit_or_now do
        Gitlab::EventStore.publish(event)
      end
    end

    def handle_date_changes(issue)
      return unless issue.previous_changes.slice('due_date', 'start_date').any?

      GraphqlTriggers.issuable_dates_updated(issue)
    end

    def clone_issue(issue)
      target_container = params.delete(:target_clone_container)
      with_notes = params.delete(:clone_with_notes)

      return unless target_container &&
        issue.can_clone?(current_user, target_container)

      # we've pre-empted this from running in #execute, so let's go ahead and update the Issue now.
      update(issue)

      if Feature.enabled?(:work_item_move_and_clone, container)
        clone_service_container = target_container.is_a?(Project) ? target_container.project_namespace : target_container
        ::WorkItems::DataSync::CloneService.new(
          work_item: issue, current_user: current_user, target_namespace: clone_service_container,
          params: { clone_with_notes: with_notes }
        ).execute[:work_item]
      elsif target_container.is_a?(Project)
        Issues::CloneService.new(container: project, current_user: current_user).execute(
          issue, target_container, with_notes: with_notes
        )
      end
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
      return unless issue.previous_changes.include?('work_item_type_id')

      do_handle_issue_type_change(issue)
    end

    def do_handle_issue_type_change(issue)
      old_work_item_type = ::WorkItems::Type.find_by_id(issue.work_item_type_id_before_last_save).base_type
      SystemNoteService.change_issue_type(issue, current_user, old_work_item_type)

      ::IncidentManagement::IssuableEscalationStatuses::CreateService.new(issue).execute if issue.supports_escalation?
    end

    def move_to_same_container?(issue, target_container)
      target_container_identifier = target_container.id

      target_container_identifier = target_container.project_namespace_id if target_container.is_a?(Project)

      issue.namespace_id == target_container_identifier
    end

    override :allowed_update_params
    def allowed_update_params(params)
      super.except(:issue_type)
    end
  end
end

Issues::UpdateService.prepend_mod_with('Issues::UpdateService')
