module MergeRequests
  class BaseService < ::IssuableBaseService
    prepend EE::MergeRequests::BaseService

    def create_note(merge_request)
      SystemNoteService.change_status(merge_request, merge_request.target_project, current_user, merge_request.state, nil)
    end

    def create_title_change_note(issuable, old_title)
      removed_wip = MergeRequest.work_in_progress?(old_title) && !issuable.work_in_progress?
      added_wip = !MergeRequest.work_in_progress?(old_title) && issuable.work_in_progress?
      changed_title = MergeRequest.wipless_title(old_title) != issuable.wipless_title

      if removed_wip
        SystemNoteService.remove_merge_request_wip(issuable, issuable.project, current_user)
      elsif added_wip
        SystemNoteService.add_merge_request_wip(issuable, issuable.project, current_user)
      end

      super if changed_title
    end

    def hook_data(merge_request, action, oldrev = nil)
      hook_data = merge_request.to_hook_data(current_user)
      hook_data[:object_attributes][:url] = Gitlab::UrlBuilder.build(merge_request)
      hook_data[:object_attributes][:action] = action
      if oldrev && !Gitlab::Git.blank_ref?(oldrev)
        hook_data[:object_attributes][:oldrev] = oldrev
      end
      hook_data
    end

    def execute_hooks(merge_request, action = 'open', oldrev = nil)
      if merge_request.project
        merge_data = hook_data(merge_request, action, oldrev)
        merge_request.project.execute_hooks(merge_data, :merge_request_hooks)
        merge_request.project.execute_services(merge_data, :merge_request_hooks)
      end
    end

    private

    def create_assignee_note(merge_request)
      SystemNoteService.change_assignee(
        merge_request, merge_request.project, current_user, merge_request.assignee)
    end

    # Returns all origin and fork merge requests from `@project` satisfying passed arguments.
    def merge_requests_for(source_branch, mr_states: [:opened, :reopened])
      MergeRequest
        .with_state(mr_states)
        .where(source_branch: source_branch, source_project_id: @project.id)
        .preload(:source_project) # we don't need a #includes since we're just preloading for the #select
        .select(&:source_project)
    end

    def pipeline_merge_requests(pipeline)
      merge_requests_for(pipeline.ref).each do |merge_request|
        next unless pipeline == merge_request.head_pipeline

        yield merge_request
      end
    end

    def commit_status_merge_requests(commit_status)
      merge_requests_for(commit_status.ref).each do |merge_request|
        pipeline = merge_request.head_pipeline

        next unless pipeline
        next unless pipeline.sha == commit_status.sha

        yield merge_request
      end
    end
  end
end
