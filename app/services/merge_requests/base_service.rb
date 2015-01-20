module MergeRequests
  class BaseService < ::IssuableBaseService

    def create_note(merge_request)
      Note.create_status_change_note(merge_request, merge_request.target_project, current_user, merge_request.state, nil)
    end

    def execute_hooks(merge_request, action = 'open')
      if merge_request.project
        hook_data = merge_request.to_hook_data(current_user)
        merge_request_url = Gitlab::UrlBuilder.new(:merge_request).build(merge_request.id)
        hook_data[:object_attributes][:url] = merge_request_url
        hook_data[:object_attributes][:action] = action
        merge_request.project.execute_hooks(hook_data, :merge_request_hooks)
      end
    end
  end
end
