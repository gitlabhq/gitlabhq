# frozen_string_literal: true

module MergeRequests
  class BaseService < ::IssuableBaseService
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
      merge_request.project.execute_services(merge_data, :merge_request_hooks)
    end

    def cleanup_environments(merge_request)
      Ci::StopEnvironmentsService.new(merge_request.source_project, current_user)
                                 .execute_for_merge_request(merge_request)
    end

    def source_project
      @source_project ||= merge_request.source_project
    end

    def target_project
      @target_project ||= merge_request.target_project
    end

    # Don't try to print expensive instance variables.
    def inspect
      "#<#{self.class} #{merge_request.to_reference(full: true)}>"
    end

    private

    def create(merge_request)
      self.params = assign_allowed_merge_params(merge_request, params)

      super
    end

    def update(merge_request)
      self.params = assign_allowed_merge_params(merge_request, params)

      super
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
    end

    def merge_request_metrics_service(merge_request)
      MergeRequestMetricsService.new(merge_request.metrics)
    end

    def create_assignee_note(merge_request, old_assignees)
      SystemNoteService.change_issuable_assignees(
        merge_request, merge_request.project, current_user, old_assignees)
    end

    def create_pipeline_for(merge_request, user)
      MergeRequests::CreatePipelineService.new(project, user).execute(merge_request)
    end

    def can_use_merge_request_ref?(merge_request)
      Feature.enabled?(:ci_use_merge_request_ref, project, default_enabled: true) &&
        !merge_request.for_fork?
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
        next unless pipeline == merge_request.head_pipeline

        yield merge_request
      end
    end
  end
end

MergeRequests::BaseService.prepend_if_ee('EE::MergeRequests::BaseService')
