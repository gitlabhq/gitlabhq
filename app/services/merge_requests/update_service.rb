# frozen_string_literal: true

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    extend ::Gitlab::Utils::Override

    def execute(merge_request)
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

    def handle_changes(merge_request, options)
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])
      old_reviewers = old_associations.fetch(:reviewers, [])

      if has_changes?(merge_request, old_labels: old_labels, old_assignees: old_assignees, old_reviewers: old_reviewers)
        todo_service.resolve_todos_for_target(merge_request, current_user)
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

      handle_assignees_change(merge_request, old_assignees) if merge_request.assignees != old_assignees

      handle_reviewers_change(merge_request, old_reviewers) if merge_request.reviewers != old_reviewers

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

    def handle_milestone_change(merge_request)
      return if skip_milestone_email

      return unless merge_request.previous_changes.include?('milestone_id')

      if merge_request.milestone.nil?
        notification_service.async.removed_milestone_merge_request(merge_request, current_user)
      else
        notification_service.async.changed_milestone_merge_request(merge_request, merge_request.milestone, current_user)
      end
    end

    def handle_assignees_change(merge_request, old_assignees)
      create_assignee_note(merge_request, old_assignees)
      notification_service.async.reassigned_merge_request(merge_request, current_user, old_assignees)
      todo_service.reassigned_assignable(merge_request, current_user, old_assignees)

      new_assignees = merge_request.assignees - old_assignees
      merge_request_activity_counter.track_users_assigned_to_mr(users: new_assignees)
    end

    def handle_reviewers_change(merge_request, old_reviewers)
      affected_reviewers = (old_reviewers + merge_request.reviewers) - (old_reviewers & merge_request.reviewers)
      create_reviewer_note(merge_request, old_reviewers)
      notification_service.async.changed_reviewer_of_merge_request(merge_request, current_user, old_reviewers)
      todo_service.reassigned_reviewable(merge_request, current_user, old_reviewers)
      invalidate_cache_counts(merge_request, users: affected_reviewers.compact)

      new_reviewers = merge_request.reviewers - old_reviewers
      merge_request_activity_counter.track_users_review_requested(users: new_reviewers)
    end

    def create_branch_change_note(issuable, branch_type, old_branch, new_branch)
      SystemNoteService.change_branch(
        issuable, issuable.project, current_user, branch_type,
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
  end
end

MergeRequests::UpdateService.prepend_if_ee('EE::MergeRequests::UpdateService')
