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

    def execute(merge_request, source = nil)
      return if merge_request.merged?

      # Mark the merge request as merged, everything that happens afterwards is
      # executed once
      merge_request.mark_as_merged

      create_event(merge_request)
      todo_service.merge_merge_request(merge_request, current_user)

      merge_request_activity_counter.track_merge_mr_action(user: current_user)

      create_note(merge_request, source)
      close_issues(merge_request)
      notification_service.merge_mr(merge_request, current_user)
      invalidate_cache_counts(merge_request, users: merge_request.assignees | merge_request.reviewers)
      merge_request.update_project_counter_caches
      delete_non_latest_diffs(merge_request)
      cancel_review_app_jobs!(merge_request)
      cleanup_environments(merge_request)
      cleanup_refs(merge_request)
      deactivate_pages_deployments(merge_request)
      cancel_auto_merges_targeting_source_branch(merge_request)

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
        merge_request.merge_requests_closing_issues.preload_issue.find_each(batch_size: 100) do |closing_issue| # rubocop:disable CodeReuse/ActiveRecord -- Would require exact redefinition of the method
          close_issue(closing_issue.issue, merge_request, !closing_issue.from_mr_description)
        end
      end
    end

    def close_issue(issue, merge_request, skip_authorization = false)
      # We are intentionally only closing Issues asynchronously (excluding ExternalIssues)
      # as the worker only supports finding an Issue. We are also only experiencing
      # SQL timeouts when closing an Issue.
      if issue.is_a?(Issue)
        # Doing this check here only to save a scheduled worker. The worker will also do this policy check.
        return if !skip_authorization && !current_user.can?(:update_issue, issue)
        return unless issue.autoclose_by_merged_closing_merge_request?

        MergeRequests::CloseIssueWorker.perform_async(
          project.id,
          current_user.id,
          issue.id,
          merge_request.id,
          { skip_authorization: skip_authorization }
        )
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
