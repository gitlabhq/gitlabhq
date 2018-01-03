module MergeRequests
  class AddTodoWhenBuildFailsService < MergeRequests::BaseService
    # Adds a todo to the parent merge_request when a CI build fails
    #
    def execute(commit_status)
      return if commit_status.allow_failure? || commit_status.retried?

      commit_status_merge_requests(commit_status) do |merge_request|
        todo_service.merge_request_build_failed(merge_request)
      end
    end

    # Closes any pending build failed todos for the parent MRs when a
    # build is retried
    #
    def close(commit_status)
      commit_status_merge_requests(commit_status) do |merge_request|
        todo_service.merge_request_build_retried(merge_request)
      end
    end

    def close_all(pipeline)
      pipeline_merge_requests(pipeline) do |merge_request|
        todo_service.merge_request_build_retried(merge_request)
      end
    end
  end
end
