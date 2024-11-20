# frozen_string_literal: true

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    extend ::Gitlab::Utils::Override

    def initialize(project:, current_user: nil, params: {})
      super

      @target_branch_was_deleted = @params.delete(:target_branch_was_deleted)
    end

    def execute(merge_request)
      if Gitlab::Utils.to_boolean(params[:draft])
        merge_request.title = merge_request.draft_title
      end

      if params.key?(:merge_after)
        merge_after = params.delete(:merge_after)
        UpdateMergeScheduleService.new(merge_request, merge_after: merge_after).execute
      end

      update_merge_request_with_specialized_service(merge_request) || general_fallback(merge_request)
    end

    def handle_changes(merge_request, options)
      super
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])
      old_reviewers = old_associations.fetch(:reviewers, [])
      old_timelogs = old_associations.fetch(:timelogs, [])
      changed_fields = merge_request.previous_changes.keys

      resolve_todos(merge_request, old_labels, old_assignees, old_reviewers)

      if merge_request.previous_changes.include?('title') ||
          merge_request.previous_changes.include?('description')
        todo_service.update_merge_request(merge_request, current_user, old_mentioned_users)
      end

      handle_target_branch_change(merge_request)
      handle_draft_status_change(merge_request, changed_fields)

      track_title_and_desc_edits(changed_fields)
      track_discussion_lock_toggle(merge_request, changed_fields)
      track_time_estimate_and_spend_edits(merge_request, old_timelogs, changed_fields)
      track_labels_change(merge_request, old_labels)

      notify_if_labels_added(merge_request, old_labels)
      notify_if_mentions_added(merge_request, old_mentioned_users)

      # Since #mark_as_unchecked triggers an update action through the MR's
      #   state machine, we want to push this as far down in the process so we
      #   avoid resetting #ActiveModel::Dirty
      #
      if merge_request.previous_changes.include?('target_branch') ||
          merge_request.previous_changes.include?('source_branch')
        merge_request.mark_as_unchecked unless merge_request.unchecked?
      end
    end

    def handle_task_changes(merge_request)
      todo_service.resolve_todos_for_target(merge_request, current_user)
      todo_service.update_merge_request(merge_request, current_user)
    end

    def reopen_service
      MergeRequests::ReopenService
    end

    def close_service
      MergeRequests::CloseService
    end

    def after_update(merge_request, old_associations)
      super

      merge_request.cache_merge_request_closes_issues!(current_user) unless merge_request.auto_merge_enabled?
      @trigger_work_item_updated = true
    end

    private

    attr_reader :target_branch_was_deleted

    def trigger_updated_work_item_on_closing_issues(merge_request, old_closing_issues_ids)
      new_issue_ids = merge_request.merge_requests_closing_issues.limit(1000).pluck(:issue_id) # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be the same in the model
      all_issue_ids = new_issue_ids | old_closing_issues_ids
      return if all_issue_ids.blank?

      WorkItem.id_in(all_issue_ids).find_each(batch_size: 100) do |work_item| # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be the same in the model
        GraphqlTriggers.work_item_updated(work_item)
      end
    end

    override :associations_before_update
    def associations_before_update(merge_request)
      super.merge(
        closing_issues_ids: merge_request.merge_requests_closing_issues.limit(1000).pluck(:issue_id) # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be the same in the model
      )
    end

    override :change_state
    def change_state(merge_request)
      return unless super

      @trigger_work_item_updated = true
    end

    override :trigger_update_subscriptions
    def trigger_update_subscriptions(merge_request, old_associations)
      return unless @trigger_work_item_updated

      trigger_updated_work_item_on_closing_issues(
        merge_request,
        old_associations.fetch(:closing_issues_ids, [])
      )
    end

    def general_fallback(merge_request)
      # We don't allow change of source/target projects and source branch
      # after merge request was created
      params.delete(:source_project_id)
      params.delete(:target_project_id)
      params.delete(:source_branch)

      if merge_request.closed_or_merged_without_fork?
        params.delete(:target_branch)
        params.delete(:force_remove_source_branch)
      end

      update_task_event(merge_request) || update(merge_request)
    end

    def track_title_and_desc_edits(changed_fields)
      tracked_fields = %w[title description]

      return unless changed_fields.any? { |field| tracked_fields.include?(field) }

      tracked_fields.each do |action|
        next unless changed_fields.include?(action)

        merge_request_activity_counter
          .public_send("track_#{action}_edit_action".to_sym, user: current_user) # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def track_discussion_lock_toggle(merge_request, changed_fields)
      return unless changed_fields.include?('discussion_locked')

      if merge_request.discussion_locked
        merge_request_activity_counter.track_discussion_locked_action(user: current_user)
      else
        merge_request_activity_counter.track_discussion_unlocked_action(user: current_user)
      end
    end

    def track_time_estimate_and_spend_edits(merge_request, old_timelogs, changed_fields)
      merge_request_activity_counter.track_time_estimate_changed_action(user: current_user) if changed_fields.include?('time_estimate')
      merge_request_activity_counter.track_time_spent_changed_action(user: current_user) if old_timelogs != merge_request.timelogs
    end

    def track_labels_change(merge_request, old_labels)
      return if Set.new(merge_request.labels) == Set.new(old_labels)

      merge_request_activity_counter.track_labels_changed_action(user: current_user)
    end

    def notify_if_labels_added(merge_request, old_labels)
      added_labels = merge_request.labels - old_labels

      return unless added_labels.present?

      notification_service.async.relabeled_merge_request(
        merge_request,
        added_labels,
        current_user
      )
    end

    def notify_if_mentions_added(merge_request, old_mentioned_users)
      added_mentions = merge_request.mentioned_users(current_user) - old_mentioned_users

      return unless added_mentions.present?

      notification_service.async.new_mentions_in_merge_request(
        merge_request,
        added_mentions,
        current_user
      )
    end

    def resolve_todos(merge_request, old_labels, old_assignees, old_reviewers)
      return unless has_changes?(merge_request, old_labels: old_labels, old_assignees: old_assignees, old_reviewers: old_reviewers)

      resolve_todos_for(merge_request)
    end

    def handle_target_branch_change(merge_request)
      return unless merge_request.previous_changes.include?('target_branch')

      create_branch_change_note(
        merge_request,
        'target',
        target_branch_was_deleted ? 'delete' : 'update',
        merge_request.previous_changes['target_branch'].first,
        merge_request.target_branch
      )

      delete_approvals_on_target_branch_change(merge_request)

      # `target_branch_was_deleted` is set to true when MR gets re-targeted due to
      # deleted target branch. In this case we don't want to create a new pipeline
      # on behalf of MR author.
      # We nullify head_pipeline_id to force that a new pipeline is explicitly
      # created in order to pass mergeability checks.
      if target_branch_was_deleted
        merge_request.head_pipeline_id = nil
        merge_request.retargeted = true
      else
        refresh_pipelines_on_merge_requests(merge_request, allow_duplicate: true)
      end

      abort_auto_merge(merge_request, 'target branch was changed')
    end

    def handle_draft_status_change(merge_request, changed_fields)
      return unless changed_fields.include?("title")

      old_title, new_title = merge_request.previous_changes["title"]
      old_title_draft = MergeRequest.draft?(old_title)
      new_title_draft = MergeRequest.draft?(new_title)

      if old_title_draft || new_title_draft
        # notify the draft status changed. Added/removed message is handled in the
        # email template itself, see `change_in_merge_request_draft_status_email` template.
        notify_draft_status_changed(merge_request)
        trigger_merge_request_status_updated(merge_request)
        publish_draft_change_event(merge_request)
      end

      if !old_title_draft && new_title_draft
        # Marked as Draft
        merge_request_activity_counter.track_marked_as_draft_action(user: current_user)
      elsif old_title_draft && !new_title_draft
        # Unmarked as Draft
        merge_request_activity_counter.track_unmarked_as_draft_action(user: current_user)
      end
    end

    def publish_draft_change_event(merge_request)
      Gitlab::EventStore.publish(
        MergeRequests::DraftStateChangeEvent.new(
          data: { current_user_id: current_user.id, merge_request_id: merge_request.id }
        )
      )
    end

    def notify_draft_status_changed(merge_request)
      notification_service.async.change_in_merge_request_draft_status(
        merge_request,
        current_user
      )
    end

    def create_branch_change_note(issuable, branch_type, event_type, old_branch, new_branch)
      SystemNoteService.change_branch(
        issuable, issuable.project, current_user, branch_type, event_type,
        old_branch, new_branch)
    end

    override :before_update
    def before_update(merge_request, skip_spam_check: false)
      merge_request.check_for_spam(user: current_user, action: :update) unless skip_spam_check
    end

    override :handle_quick_actions
    def handle_quick_actions(merge_request)
      super

      # Ensure this parameter does not get used as an attribute
      rebase = params.delete(:rebase)

      if rebase
        rebase_from_quick_action(merge_request)
        # Ignore "/merge" if "/rebase" is used to avoid an unexpected race
        params.delete(:merge)
      end

      merge_from_quick_action(merge_request) if params[:merge]
    end

    def rebase_from_quick_action(merge_request)
      merge_request.rebase_async(current_user.id)
    end

    def merge_from_quick_action(merge_request)
      last_diff_sha = params.delete(:merge)

      ::MergeRequests::MergeOrchestrationService
        .new(project, current_user, { sha: last_diff_sha })
        .execute(merge_request)
    end

    override :quick_action_options
    def quick_action_options
      { merge_request_diff_head_sha: params.delete(:merge_request_diff_head_sha) }
    end

    def update_merge_request_with_specialized_service(merge_request)
      return unless params.delete(:use_specialized_service)

      # If we're attempting to modify only a single attribute, look up whether
      #   we have a specialized, targeted service we should use instead. We may
      #   in the future extend this to include specialized services that operate
      #   on multiple attributes, but for now limit to only single attribute
      #   updates.
      #
      return unless params.one?

      attempt_specialized_update_services(merge_request, params.each_key.first.to_sym)
    end

    def attempt_specialized_update_services(merge_request, attribute)
      case attribute
      when :assignee_ids, :assignee_id
        assignees_service.execute(merge_request)
      when :spend_time
        add_time_spent_service.execute(merge_request)
      end
    end

    def assignees_service
      @assignees_service ||= ::MergeRequests::UpdateAssigneesService
        .new(project: project, current_user: current_user, params: params)
    end

    def add_time_spent_service
      @add_time_spent_service ||= ::MergeRequests::AddSpentTimeService.new(project: project, current_user: current_user, params: params)
    end

    def new_user_ids(merge_request, user_ids, attribute)
      # prime the cache - prevent N+1 lookup during authorization loop.
      return [] if user_ids.empty?

      merge_request.project.team.max_member_access_for_user_ids(user_ids)
      User.id_in(user_ids).map do |user|
        if user.can?(:read_merge_request, merge_request)
          user.id
        else
          merge_request.errors.add(
            attribute,
            "Cannot assign #{user.to_reference} to #{merge_request.to_reference}"
          )
          nil
        end
      end.compact
    end

    def resolve_todos_for(merge_request)
      service_user = current_user

      merge_request.run_after_commit_or_now do
        ::MergeRequests::ResolveTodosService.new(merge_request, service_user).async_execute
      end
    end

    def filter_sentinel_values(param)
      param.reject { _1 == 0 }
    end

    def trigger_merge_request_status_updated(merge_request)
      GraphqlTriggers.merge_request_merge_status_updated(merge_request)
    end

    def delete_approvals_on_target_branch_change(_merge_request)
      # Overridden in EE. No-op since we only want to delete approvals in EE.
    end
  end
end

MergeRequests::UpdateService.prepend_mod_with('MergeRequests::UpdateService')
