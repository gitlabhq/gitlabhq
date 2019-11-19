# frozen_string_literal: true

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    def execute(merge_request)
      # We don't allow change of source/target projects and source branch
      # after merge request was created
      params.delete(:source_project_id)
      params.delete(:target_project_id)
      params.delete(:source_branch)

      merge_from_quick_action(merge_request) if params[:merge]

      if merge_request.closed_without_fork?
        params.delete(:target_branch)
        params.delete(:force_remove_source_branch)
      end

      handle_wip_event(merge_request)
      update_task_event(merge_request) || update(merge_request)
    end

    def handle_changes(merge_request, options)
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])

      if has_changes?(merge_request, old_labels: old_labels, old_assignees: old_assignees)
        todo_service.mark_pending_todos_as_done(merge_request, current_user)
      end

      if merge_request.previous_changes.include?('title') ||
          merge_request.previous_changes.include?('description')
        todo_service.update_merge_request(merge_request, current_user, old_mentioned_users)
      end

      if merge_request.previous_changes.include?('target_branch')
        create_branch_change_note(merge_request, 'target',
                                  merge_request.previous_changes['target_branch'].first,
                                  merge_request.target_branch)

        abort_auto_merge(merge_request, 'target branch was changed')
      end

      if merge_request.assignees != old_assignees
        create_assignee_note(merge_request, old_assignees)
        notification_service.async.reassigned_merge_request(merge_request, current_user, old_assignees)
        todo_service.reassigned_issuable(merge_request, current_user, old_assignees)
      end

      if merge_request.previous_changes.include?('target_branch') ||
          merge_request.previous_changes.include?('source_branch')
        merge_request.mark_as_unchecked
      end

      handle_milestone_change(merge_request)

      added_labels = merge_request.labels - old_labels
      if added_labels.present?
        notification_service.async.relabeled_merge_request(
          merge_request,
          added_labels,
          current_user
        )
      end

      added_mentions = merge_request.mentioned_users(current_user) - old_mentioned_users

      if added_mentions.present?
        notification_service.async.new_mentions_in_merge_request(
          merge_request,
          added_mentions,
          current_user
        )
      end
    end

    def handle_task_changes(merge_request)
      todo_service.mark_pending_todos_as_done(merge_request, current_user)
      todo_service.update_merge_request(merge_request, current_user)
    end

    def merge_from_quick_action(merge_request)
      last_diff_sha = params.delete(:merge)
      return unless merge_request.mergeable_with_quick_action?(current_user, last_diff_sha: last_diff_sha)

      merge_request.update(merge_error: nil)

      if merge_request.head_pipeline_active?
        AutoMergeService.new(project, current_user, { sha: last_diff_sha }).execute(merge_request, AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
      else
        merge_request.merge_async(current_user.id, { sha: last_diff_sha })
      end
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

    def handle_milestone_change(merge_request)
      return if skip_milestone_email

      return unless merge_request.previous_changes.include?('milestone_id')

      if merge_request.milestone.nil?
        notification_service.async.removed_milestone_merge_request(merge_request, current_user)
      else
        notification_service.async.changed_milestone_merge_request(merge_request, merge_request.milestone, current_user)
      end
    end

    def create_branch_change_note(issuable, branch_type, old_branch, new_branch)
      SystemNoteService.change_branch(
        issuable, issuable.project, current_user, branch_type,
        old_branch, new_branch)
    end
  end
end

MergeRequests::UpdateService.prepend_if_ee('EE::MergeRequests::UpdateService')
