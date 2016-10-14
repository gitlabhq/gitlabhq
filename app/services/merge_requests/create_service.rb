module MergeRequests
  class CreateService < MergeRequests::BaseService
    def execute
      # @project is used to determine whether the user can set the merge request's
      # assignee, milestone and labels. Whether they can depends on their
      # permissions on the target project.
      source_project = @project
      @project = Project.find(params[:target_project_id]) if params[:target_project_id]

      params[:target_project_id] ||= source_project.id

      merge_request = MergeRequest.new
      merge_request.source_project = source_project

      create(merge_request)
    end

    def after_create(issuable)
      event_service.open_mr(issuable, current_user)
      notification_service.new_merge_request(issuable, current_user)
      todo_service.new_merge_request(issuable, current_user)
      issuable.cache_merge_request_closes_issues!(current_user)
    end
  end
end
