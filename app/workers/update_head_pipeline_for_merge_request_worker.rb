class UpdateHeadPipelineForMergeRequestWorker
  include ApplicationWorker

  sidekiq_options queue: 'pipeline_default'

  def perform(merge_request_id)
    merge_request = MergeRequest.find(merge_request_id)
    pipeline = Ci::Pipeline.where(project: merge_request.source_project, ref: merge_request.source_branch).last

    return unless pipeline && pipeline.latest?
    raise ArgumentError, 'merge request sha does not equal pipeline sha' if merge_request.diff_head_sha != pipeline.sha

    merge_request.update_attribute(:head_pipeline_id, pipeline.id)
  end
end
