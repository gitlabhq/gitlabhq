# frozen_string_literal: true

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    extend ::Gitlab::Utils::Override

    def initialize(project:, current_user: nil, params: {})
      super

      @target_branch_was_deleted = @params.delete(:target_branch_was_deleted)
    end

    def execute(merge_request)
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
      handle_milestone_change(merge_request)
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

    def after_update(issuable)
      issuable.cache_merge_request_closes_issues!(current_user)
    end

    private

    attr_reader :target_branch_was_deleted

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
      tracked_fields = %w(title description)

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

      service_user = current_user

      merge_request.run_after_commit_or_now do
        ::MergeRequests::ResolveTodosService.new(merge_request, service_user).async_execute
      end
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

      abort_auto_merge(merge_request, 'target branch was changed')
    end

    def handle_draft_status_change(merge_request, changed_fields)
      return unless changed_fields.include?("title")

      old_title, new_title = merge_request.previous_changes["title"]
      old_title_wip = MergeRequest.work_in_progress?(old_title)
      new_title_wip = MergeRequest.work_in_progress?(new_title)

      if !old_title_wip && new_title_wip
        # Marked as Draft/WIP
        #
        merge_request_activity_counter
          .track_marked_as_draft_action(user: current_user)
      elsif old_title_wip && !new_title_wip
        # Unmarked as Draft/WIP
        #
        notify_draft_status_changed(merge_request)

        merge_request_activity_counter
          .track_unmarked_as_draft_action(user: current_user)
      end
    end

    def notify_draft_status_changed(merge_request)
      notification_service.async.change_in_merge_request_draft_status(
        merge_request,
        current_user
      )
    end

    def handle_milestone_change(merge_request)
      return if skip_milestone_email

      return unless merge_request.previous_changes.include?('milestone_id')

      merge_request_activity_counter.track_milestone_changed_action(user: current_user)

      previous_milestone = Milestone.find_by_id(merge_request.previous_changes['milestone_id'].first)
      delete_milestone_total_merge_requests_counter_cache(previous_milestone)

      if merge_request.milestone.nil?
        notification_service.async.removed_milestone_merge_request(merge_request, current_user)
      else
        notification_service.async.changed_milestone_merge_request(merge_request, merge_request.milestone, current_user)

        delete_milestone_total_merge_requests_counter_cache(merge_request.milestone)
      end
    end

    def create_branch_change_note(issuable, branch_type, event_type, old_branch, new_branch)
      SystemNoteService.change_branch(
        issuable, issuable.project, current_user, branch_type, event_type,
        old_branch, new_branch)
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

      MergeRequests::MergeOrchestrationService
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
      else
        nil
      end
    end

    def assignees_service
      @assignees_service ||= ::MergeRequests::UpdateAssigneesService
        .new(project: project, current_user: current_user, params: params)
    end

    def add_time_spent_service
      @add_time_spent_service ||= ::MergeRequests::AddSpentTimeService.new(project: project, current_user: current_user, params: params)
    end
  end
end

MergeRequests::UpdateService.prepend_mod_with('MergeRequests::UpdateService')
