# frozen_string_literal: true

module MergeRequests
  # PostMergeService class
  #
  # Mark existing merge request as merged
  # and execute all hooks and notifications
  #
  class PostMergeService < MergeRequests::BaseService
    include RemovesRefs

    MAX_RETARGET_MERGE_REQUESTS = 4
    BATCH_SIZE = 100

    def execute(merge_request, source = nil)
      return if merge_request.merged?

      # Mark the merge request as merged, everything that happens afterwards is
      # executed once
      unless merge_request.mark_as_merged
        Gitlab::AppLogger.warn(
          message: 'Failed to mark merge request as merged',
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_id: merge_request.project_id,
          delete_source_branch: params[:delete_source_branch],
          errors: merge_request.errors.full_messages
        )
      end

      create_event(merge_request)
      todo_service.merge_merge_request(merge_request, current_user)

      merge_request_activity_counter.track_merge_mr_action(user: current_user)

      create_note(merge_request, source)
      close_issues(merge_request)
      notification_service.merge_mr(merge_request, current_user)
      invalidate_all_users_cache_count(merge_request)
      merge_request.invalidate_project_counter_caches
      delete_non_latest_diffs(merge_request)
      cancel_review_app_jobs!(merge_request)
      cleanup_environments(merge_request)
      cleanup_refs(merge_request)
      deactivate_pages_deployments(merge_request)
      cancel_auto_merges_targeting_source_branch(merge_request)
      trigger_user_merge_request_updated(merge_request)

      execute_hooks(merge_request, 'merge')
    end

    def create_note(merge_request, source)
      SystemNoteService.change_status(
        merge_request,
        merge_request.target_project,
        current_user,
        merge_request.state,
        source
      )
    end

    private

    def close_issues(merge_request)
      return unless merge_request.target_branch == project.default_branch

      if merge_request.target_project.has_external_issue_tracker?
        merge_request.closes_issues(current_user).each do |issue|
          close_issue(issue, merge_request)
        end
      else
        delay = 0
        merge_request.merge_requests_closing_issues.preload_issue
                     .find_each(batch_size: BATCH_SIZE).with_index(1) do |closing_issue, index| # rubocop:disable CodeReuse/ActiveRecord -- Would require exact redefinition of the method
          delay += 5 if (index % 5) == 0
          close_issue(closing_issue.issue, merge_request, !closing_issue.from_mr_description, delay: delay)
        end
      end
    end

    def close_issue(issue, merge_request, skip_authorization = false, delay: 0)
      # We are intentionally only closing Issues asynchronously (excluding ExternalIssues)
      # as the worker only supports finding an Issue. We are also only experiencing
      # SQL timeouts when closing an Issue.
      if issue.is_a?(Issue)
        # Doing this check here only to save a scheduled worker. The worker will also do this policy check.
        return if !skip_authorization && !current_user.can?(:update_issue, issue)
        return unless issue.autoclose_by_merged_closing_merge_request?

        worker_args = [project.id,
          current_user.id,
          issue.id,
          merge_request.id,
          { skip_authorization: skip_authorization }]
        MergeRequests::CloseIssueWorker.perform_in(delay.minutes, *worker_args)
      else
        Issues::CloseService.new(container: project, current_user: current_user).execute(issue, commit: merge_request)
      end
    end

    def delete_non_latest_diffs(merge_request)
      DeleteNonLatestDiffsService.new(merge_request).execute
    end

    def create_merge_event(merge_request, current_user)
      EventCreateService.new.merge_mr(merge_request, current_user)
    end

    def create_event(merge_request)
      # Making sure MergeRequest::Metrics updates are in sync with
      # Event creation.
      Event.transaction do
        merge_event = create_merge_event(merge_request, current_user)
        merge_request_metrics_service(merge_request).merge(merge_event)
      end
    end

    def cancel_auto_merges_targeting_source_branch(merge_request)
      return unless params[:delete_source_branch]

      merge_request.source_project
        .merge_requests
        .by_target_branch(merge_request.source_branch)
        .with_auto_merge_enabled.each do |targetting_merge_request|
          if targetting_merge_request.auto_merge_strategy == ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS
            abort_auto_merge_with_todo(targetting_merge_request, "target branch was merged in !#{merge_request.iid}")
          end
        end
    end
  end
end

MergeRequests::PostMergeService.prepend_mod_with('MergeRequests::PostMergeService')
