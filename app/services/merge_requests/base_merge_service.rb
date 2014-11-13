module MergeRequests
  class BaseMergeService

    private

    def notification
      NotificationService.new
    end

    def create_merge_event(merge_request, current_user)
      EventCreateService.new.merge_mr(merge_request, current_user)
    end

    def execute_project_hooks(merge_request)
      if merge_request.project
        hook_data = merge_request.to_hook_data(current_user)
        merge_request.project.execute_hooks(hook_data, :merge_request_hooks)
      end
    end
  end
end
