class UpdateHeadPipelineForMergeRequestWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(merge_request_id)
    merge_request = MergeRequest.find(merge_request_id)
    pipeline = Ci::Pipeline.where(project: merge_request.source_project, ref: merge_request.source_branch).last

    return unless pipeline && pipeline.latest?

    if merge_request.diff_head_sha != pipeline.sha
      log_error_message_for(merge_request)

      return
    end

    merge_request.update_attribute(:head_pipeline_id, pipeline.id)
  end

  def log_error_message_for(merge_request)
    Rails.logger.error(
      "Outdated head pipeline for active merge request: id=#{merge_request.id}, source_branch=#{merge_request.source_branch}, diff_head_sha=#{merge_request.diff_head_sha}"
    )
  end
end
