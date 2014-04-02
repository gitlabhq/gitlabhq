module MergeReques
  class CreateService < MergeRequests::BaseService
    def execute
      merge_request = MergeRequest.new(params)
      merge_request.source_project = project
      merge_request.author = current_user

      if merge_request.save
        event_service.open_mr(merge_request, current_user)
        notification_service.new_merge_request(merge_request, current_user)
        merge_request.create_cross_references!(merge_request.project, current_user)
        execute_hooks(merge_request)
      end

      merge_request
    end
  end
end
