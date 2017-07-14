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
      merge_request.head_pipeline = head_pipeline_for(merge_request)

      create(merge_request)
    end

    def after_create(issuable)
      event_service.open_mr(issuable, current_user)
      notification_service.new_merge_request(issuable, current_user)
      todo_service.new_merge_request(issuable, current_user)
      issuable.cache_merge_request_closes_issues!(current_user)
    end

    private

    def head_pipeline_for(merge_request)
      return unless merge_request.source_project

      sha = merge_request.source_branch_sha
      return unless sha

      pipelines = merge_request.source_project.pipelines.where(ref: merge_request.source_branch, sha: sha)

      pipelines.order(id: :desc).first
    end
  end
end
