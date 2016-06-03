module MergeRequests
  class CreateService < MergeRequests::BaseService
    def execute
      # @project is used to determine whether the user can set the merge request's
      # assignee, milestone and labels. Whether they can depends on their
      # permissions on the target project.
      source_project = @project
      @project = Project.find(params[:target_project_id]) if params[:target_project_id]

      filter_params
      label_params = params[:label_ids]
      merge_request = MergeRequest.new(params.except(:label_ids))
      merge_request.source_project = source_project
      merge_request.target_project ||= source_project
      merge_request.author = current_user

      if merge_request.save
        merge_request.update_attributes(label_ids: label_params)
        event_service.open_mr(merge_request, current_user)
        notification_service.new_merge_request(merge_request, current_user)
        todo_service.new_merge_request(merge_request, current_user)
        merge_request.create_cross_references!(current_user)
        execute_hooks(merge_request)
      end

      merge_request
    end
  end
end
