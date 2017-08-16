module MergeRequests
  class CreateService < MergeRequests::BaseService
    def execute
      # @project is used to determine whether the user can set the merge request's
      # assignee, milestone and labels. Whether they can depends on their
      # permissions on the target project.
      source_project = @project
      @project = Project.find(params[:target_project_id]) if params[:target_project_id]

      merge_request = MergeRequest.new
      merge_request.target_project = @project
      merge_request.source_project = source_project
      merge_request.source_branch = params[:source_branch]
      merge_request.merge_params['force_remove_source_branch'] = params.delete(:force_remove_source_branch)

      create(merge_request)
    end

    def before_create(merge_request)
      user = current_user
      merge_request.run_after_commit do
        NewMergeRequestWorker.perform_async(merge_request.id, user.id)
      end
    end

    def after_create(issuable)
      todo_service.new_merge_request(issuable, current_user)
      issuable.cache_merge_request_closes_issues!(current_user)
      update_merge_requests_head_pipeline(issuable)
    end

    private

    def update_merge_requests_head_pipeline(merge_request)
      pipeline = head_pipeline_for(merge_request)
      merge_request.update(head_pipeline_id: pipeline.id) if pipeline
    end

    def head_pipeline_for(merge_request)
      return unless merge_request.source_project

      sha = merge_request.source_branch_sha
      return unless sha

      pipelines = merge_request.source_project.pipelines.where(ref: merge_request.source_branch, sha: sha)

      pipelines.order(id: :desc).first
    end
  end
end
