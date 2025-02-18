# frozen_string_literal: true

module MergeRequests
  class BaseService < ::IssuableBaseService
    extend ::Gitlab::Utils::Override
    include MergeRequests::AssignsMergeParams
    include MergeRequests::ErrorLogger

    delegate :repository, to: :project

    def initialize(project:, current_user: nil, params: {})
      super(container: project, current_user: current_user, params: params)
    end

    def create_note(merge_request, state = merge_request.state)
      SystemNoteService.change_status(merge_request, merge_request.target_project, current_user, state, nil)
    end

    def hook_data(merge_request, action, old_rev: nil, old_associations: {})
      hook_data = merge_request.to_hook_data(current_user, old_associations: old_associations, action: action)

      if old_rev && !Gitlab::Git.blank_ref?(old_rev)
        hook_data[:object_attributes][:oldrev] = old_rev
      end

      hook_data
    end

    def execute_hooks(merge_request, action = 'open', old_rev: nil, old_associations: {})
      # NOTE: Due to the async merge request diffs generation, we need to skip this for CreateService and execute it in
      #   AfterCreateService instead so that the webhook consumers receive the update when diffs are ready.
      return if merge_request.skip_ensure_merge_request_diff

      merge_data = Gitlab::Lazy.new { hook_data(merge_request, action, old_rev: old_rev, old_associations: old_associations) }
      merge_request.project.execute_hooks(merge_data, :merge_request_hooks)
      merge_request.project.execute_integrations(merge_data, :merge_request_hooks)

      execute_external_hooks(merge_request, merge_data)
      execute_group_mention_hooks(merge_request, merge_data) if action == 'open'

      enqueue_jira_connect_messages_for(merge_request)
    end

    def execute_external_hooks(merge_request, merge_data)
      # Implemented in EE
    end

    def execute_group_mention_hooks(merge_request, merge_data)
      return unless merge_request.instance_of?(MergeRequest)

      args = {
        mentionable_type: 'MergeRequest',
        mentionable_id: merge_request.id,
        hook_data: merge_data,
        is_confidential: false
      }

      merge_request.run_after_commit_or_now do
        Integrations::GroupMentionWorker.perform_async(args)
      end
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
      invalidate_cache_counts(merge_request, users: merge_request.assignees)

      new_reviewers = merge_request.reviewers - old_reviewers
      merge_request_activity_counter.track_users_review_requested(users: new_reviewers)
      merge_request_activity_counter.track_reviewers_changed_action(user: current_user)
      trigger_merge_request_reviewers_updated(merge_request)

      set_first_reviewer_assigned_at_metrics(merge_request) if new_reviewers.any?
      trigger_user_merge_request_updated(merge_request)
    end

    def cleanup_environments(merge_request)
      Environments::StopService.new(merge_request.source_project, current_user)
                               .execute_for_merge_request_pipeline(merge_request)
    end

    def cancel_review_app_jobs!(merge_request)
      environments = merge_request.environments_in_head_pipeline.in_review_folder.available
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
      return "#<#{self.class}>" unless respond_to?(:merge_request) && merge_request

      "#<#{self.class} #{merge_request.to_reference(full: true)}>"
    end

    def merge_request_activity_counter
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
    end

    def deactivate_pages_deployments(merge_request)
      Pages::DeactivateMrDeploymentsWorker.perform_async(merge_request.id)
    end

    private

    def self.constructor_container_arg(value)
      { project: value }
    end

    def refresh_pipelines_on_merge_requests(merge_request, allow_duplicate: false)
      create_pipeline_for(merge_request, current_user, async: true, allow_duplicate: allow_duplicate)
    end

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
      handle_draft_event(merge_request)
    end

    def handle_draft_event(merge_request)
      if draft_event = params.delete(:wip_event)
        # We update the title that is provided in the params or we use the mr title
        title = params[:title] || merge_request.title
        params[:title] = case draft_event
                         when 'draft' then MergeRequest.draft_title(title)
                         when 'ready' then MergeRequest.draftless_title(title)
                         end
      end
    end

    def request_duo_code_review(merge_request)
      # Overriden in EE
    end

    def filter_params(merge_request)
      super

      unless merge_request.can_allow_collaboration?(current_user)
        params.delete(:allow_collaboration)
      end

      filter_reviewer(merge_request)
      filter_suggested_reviewers
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

      reviewer_ids = User.id_in(params[:reviewer_ids]).select do |reviewer|
        user_can_read?(merge_request, reviewer)
      end.map(&:id)

      if params[:reviewer_ids].map(&:to_s) == [IssuableFinder::Params::NONE]
        params[:reviewer_ids] = []
      elsif reviewer_ids.any?
        params[:reviewer_ids] = reviewer_ids
      else
        params.delete(:reviewer_ids)
      end
    end

    def filter_suggested_reviewers
      # Implemented in EE
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

    def create_pipeline_for(merge_request, user, async: false, allow_duplicate: false)
      create_pipeline_params = params.slice(:push_options).merge(allow_duplicate: allow_duplicate)

      if async
        MergeRequests::CreatePipelineWorker.perform_async(
          project.id,
          user.id,
          merge_request.id,
          create_pipeline_params.deep_stringify_keys)
      else
        MergeRequests::CreatePipelineService
          .new(project: project, current_user: user, params: create_pipeline_params)
          .execute(merge_request)
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

    def trigger_merge_request_reviewers_updated(merge_request)
      GraphqlTriggers.merge_request_reviewers_updated(merge_request)
    end

    def trigger_merge_request_merge_status_updated(merge_request)
      GraphqlTriggers.merge_request_merge_status_updated(merge_request)
    end

    def trigger_merge_request_approval_state_updated(merge_request)
      GraphqlTriggers.merge_request_approval_state_updated(merge_request)
    end

    def trigger_user_merge_request_updated(merge_request)
      [merge_request.assignees, merge_request.reviewers].flatten.uniq.each do |user|
        GraphqlTriggers.user_merge_request_updated(user, merge_request)
      end
    end

    def set_first_reviewer_assigned_at_metrics(merge_request)
      metrics = merge_request.metrics
      return unless metrics

      current_time = Time.current

      return if metrics.reviewer_first_assigned_at && metrics.reviewer_first_assigned_at <= current_time

      metrics.update(reviewer_first_assigned_at: current_time)
    end

    def remove_approval(merge_request, user)
      MergeRequests::RemoveApprovalService.new(project: project, current_user: user)
        .execute(merge_request, skip_system_note: true, skip_notification: true, skip_updating_state: true)
    end

    def update_reviewer_state(merge_request, user, state)
      ::MergeRequests::UpdateReviewerStateService
            .new(project: merge_request.project, current_user: user)
            .execute(merge_request, state)
    end

    def abort_auto_merge_with_todo(merge_request, reason)
      response = abort_auto_merge(merge_request, reason)
      response = ServiceResponse.new(**response)
      return unless response.success?

      todo_service.merge_request_became_unmergeable(merge_request)
    end
  end
end

MergeRequests::BaseService.prepend_mod_with('MergeRequests::BaseService')
