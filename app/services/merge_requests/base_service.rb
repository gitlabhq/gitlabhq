module MergeRequests
  class BaseService < ::IssuableBaseService

    def create_note(merge_request)
      SystemNoteService.change_status(merge_request, merge_request.target_project, current_user, merge_request.state, nil)
    end

    def hook_data(merge_request, action)
      hook_data = merge_request.to_hook_data(current_user)
      merge_request_url = Gitlab::UrlBuilder.new(:merge_request).build(merge_request.id)
      hook_data[:object_attributes][:url] = merge_request_url
      hook_data[:object_attributes][:action] = action
      hook_data
    end

    def execute_hooks(merge_request, action = 'open')
      if merge_request.project
        merge_data = hook_data(merge_request, action)
        merge_request.project.execute_hooks(merge_data, :merge_request_hooks)
        merge_request.project.execute_services(merge_data, :merge_request_hooks)
      end
    end

    private

    def filter_params
      super(:merge_request)
    end
  end
end
