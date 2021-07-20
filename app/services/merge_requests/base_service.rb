# frozen_string_literal: true

module MergeRequests
  class BaseService < ::IssuableBaseService
    extend ::Gitlab::Utils::Override
    include MergeRequests::AssignsMergeParams

    def create_note(merge_request, state = merge_request.state)
      SystemNoteService.change_status(merge_request, merge_request.target_project, current_user, state, nil)
    end

    def hook_data(merge_request, action, old_rev: nil, old_associations: {})
      hook_data = merge_request.to_hook_data(current_user, old_associations: old_associations)
      hook_data[:object_attributes][:action] = action
      if old_rev && !Gitlab::Git.blank_ref?(old_rev)
        hook_data[:object_attributes][:oldrev] = old_rev
      end

      hook_data
    end

    def execute_hooks(merge_request, action = 'open', old_rev: nil, old_associations: {})
      merge_data = hook_data(merge_request, action, old_rev: old_rev, old_associations: old_associations)
      merge_request.project.execute_hooks(merge_data, :merge_request_hooks)
      merge_request.project.execute_integrations(merge_data, :merge_request_hooks)

      execute_external_hooks(merge_request, merge_data)

      enqueue_jira_connect_messages_for(merge_request)
    end

    def execute_external_hooks(merge_request, merge_data)
      # Implemented in EE
    end

    def handle_changes(merge_request, options)
      old_associations = options.fetch(:old_associations, {})
      old_assignees = old_associations.fetch(:assignees, [])
      old_reviewers = old_associations.fetch(:reviewers, [])

      handle_assignees_change(merge_request, old_assignees) if merge_request.assignees != old_assignees
      handle_reviewers_change(merge_request, old_reviewers) if merge_request.reviewers != old_reviewers
    end

    def handle_assignees_change(merge_request, old_assignees)
      MergeRequests::HandleAssigneesChangeService
        .new(project: project, current_user: current_user)
        .async_execute(merge_request, old_assignees)
    end

    def handle_reviewers_change(merge_request, old_reviewers)
      affected_reviewers = (old_reviewers + merge_request.reviewers) - (old_reviewers & merge_request.reviewers)
      create_reviewer_note(merge_request, old_reviewers)
      notification_service.async.changed_reviewer_of_merge_request(merge_request, current_user, old_reviewers)
      todo_service.reassigned_reviewable(merge_request, current_user, old_reviewers)
      invalidate_cache_counts(merge_request, users: affected_reviewers.compact)

      new_reviewers = merge_request.reviewers - old_reviewers
      merge_request_activity_counter.track_users_review_requested(users: new_reviewers)
      merge_request_activity_counter.track_reviewers_changed_action(user: current_user)
    end

    def cleanup_environments(merge_request)
      Ci::StopEnvironmentsService.new(merge_request.source_project, current_user)
                                 .execute_for_merge_request(merge_request)
    end

    def cancel_review_app_jobs!(merge_request)
      environments = merge_request.environments.in_review_folder.available
      environments.each { |environment| environment.cancel_deployment_jobs! }
    end

    def source_project
      @source_project ||= merge_request.source_project
    end

    def target_project
      @target_project ||= merge_request.target_project
    end

    # Don't try to print expensive instance variables.
    def inspect
      return "#<#{self.class}>" unless respond_to?(:merge_request)

      "#<#{self.class} #{merge_request.to_reference(full: true)}>"
    end

    def merge_request_activity_counter
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
    end

    private

    def enqueue_jira_connect_messages_for(merge_request)
      return unless project.jira_subscription_exists?

      if Atlassian::JiraIssueKeyExtractor.has_keys?(merge_request.title, merge_request.description)
        JiraConnect::SyncMergeRequestWorker.perform_async(merge_request.id, Atlassian::JiraConnect::Client.generate_update_sequence_id)
      end
    end

    def create(merge_request)
      self.params = assign_allowed_merge_params(merge_request, params)

      super
    end

    def update(merge_request)
      self.params = assign_allowed_merge_params(merge_request, params)

      super
    end

    override :handle_quick_actions
    def handle_quick_actions(merge_request)
      super
      handle_wip_event(merge_request)
    end

    def handle_wip_event(merge_request)
      if wip_event = params.delete(:wip_event)
        # We update the title that is provided in the params or we use the mr title
        title = params[:title] || merge_request.title
        params[:title] = case wip_event
                         when 'wip' then MergeRequest.wip_title(title)
                         when 'unwip' then MergeRequest.wipless_title(title)
                         end
      end
    end

    def filter_params(merge_request)
      super

      unless merge_request.can_allow_collaboration?(current_user)
        params.delete(:allow_collaboration)
      end

      filter_reviewer(merge_request)
    end

    def filter_reviewer(merge_request)
      return if params[:reviewer_ids].blank?

      unless can_admin_issuable?(merge_request)
        params.delete(:reviewer_ids)

        return
      end

      unless merge_request.allows_multiple_reviewers?
        params[:reviewer_ids] = params[:reviewer_ids].first(1)
      end

      reviewer_ids = params[:reviewer_ids].select { |reviewer_id| user_can_read?(merge_request, reviewer_id) }

      if params[:reviewer_ids].map(&:to_s) == [IssuableFinder::Params::NONE]
        params[:reviewer_ids] = []
      elsif reviewer_ids.any?
        params[:reviewer_ids] = reviewer_ids
      else
        params.delete(:reviewer_ids)
      end
    end

    def merge_request_metrics_service(merge_request)
      MergeRequestMetricsService.new(merge_request.metrics)
    end

    def create_assignee_note(merge_request, old_assignees)
      SystemNoteService.change_issuable_assignees(
        merge_request, merge_request.project, current_user, old_assignees)
    end

    def create_reviewer_note(merge_request, old_reviewers)
      SystemNoteService.change_issuable_reviewers(
        merge_request, merge_request.project, current_user, old_reviewers)
    end

    def create_pipeline_for(merge_request, user, async: false)
      if async
        MergeRequests::CreatePipelineWorker.perform_async(project.id, user.id, merge_request.id)
      else
        MergeRequests::CreatePipelineService.new(project: project, current_user: user).execute(merge_request)
      end
    end

    def abort_auto_merge(merge_request, reason)
      AutoMergeService.new(project, current_user).abort(merge_request, reason)
    end

    # Returns all origin and fork merge requests from `@project` satisfying passed arguments.
    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests_for(source_branch, mr_states: [:opened])
      @project.source_of_merge_requests
        .with_state(mr_states)
        .where(source_branch: source_branch)
        .preload(:source_project) # we don't need #includes since we're just preloading for the #select
        .select(&:source_project)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def pipeline_merge_requests(pipeline)
      pipeline.all_merge_requests.opened.each do |merge_request|
        next unless pipeline.id == merge_request.head_pipeline_id

        yield merge_request
      end
    end

    def log_error(exception:, message:, save_message_on_model: false)
      reference = merge_request.to_reference(full: true)
      data = {
        class: self.class.name,
        message: message,
        merge_request_id: merge_request.id,
        merge_request: reference,
        save_message_on_model: save_message_on_model
      }

      if exception
        Gitlab::ApplicationContext.with_context(user: current_user) do
          Gitlab::ErrorTracking.track_exception(exception, data)
        end

        data[:"exception.message"] = exception.message
      end

      # TODO: Deprecate Gitlab::GitLogger since ErrorTracking should suffice:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/216379
      data[:message] = "#{self.class.name} error (#{reference}): #{message}"
      Gitlab::GitLogger.error(data)

      merge_request.update(merge_error: message) if save_message_on_model
    end

    def delete_milestone_total_merge_requests_counter_cache(milestone)
      return unless milestone

      Milestones::MergeRequestsCountService.new(milestone).delete_cache
    end
  end
end

MergeRequests::BaseService.prepend_mod_with('MergeRequests::BaseService')
