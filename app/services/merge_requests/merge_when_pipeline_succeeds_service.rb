module MergeRequests
  class MergeWhenPipelineSucceedsService < MergeRequests::BaseService
    # Marks the passed `merge_request` to be merged when the pipeline succeeds or
    # updates the params for the automatic merge
    def execute(merge_request)
      merge_request.merge_params.merge!(params)

      # The service is also called when the merge params are updated.
      already_approved = merge_request.merge_when_pipeline_succeeds?

      unless already_approved
        merge_request.merge_when_pipeline_succeeds = true
        merge_request.merge_user = @current_user

        SystemNoteService.merge_when_pipeline_succeeds(merge_request, @project, @current_user, merge_request.diff_head_commit)
      end

      merge_request.save
    end

    # Triggers the automatic merge of merge_request once the pipeline succeeds
    def trigger(pipeline)
      return unless pipeline.success?

      pipeline_merge_requests(pipeline) do |merge_request|
        next unless merge_request.merge_when_pipeline_succeeds?

        unless merge_request.mergeable?
          todo_service.merge_request_became_unmergeable(merge_request)
          next
        end

        merge_request.merge_async(merge_request.merge_user_id, merge_request.merge_params)
      end
    end

    # Cancels the automatic merge
    def cancel(merge_request)
      if merge_request.merge_when_pipeline_succeeds? && merge_request.open?
        merge_request.reset_merge_when_pipeline_succeeds
        SystemNoteService.cancel_merge_when_pipeline_succeeds(merge_request, @project, @current_user)

        success
      else
        error("Can't cancel the automatic merge", 406)
      end
    end
  end
end
