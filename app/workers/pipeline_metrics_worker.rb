class PipelineMetricsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      merge_requests = pipeline.merge_requests.map(&:id)

      metrics = MergeRequest::Metrics.where(merge_request_id: merge_requests)
      metrics.update_all(latest_build_started_at: pipeline.started_at) if pipeline.active?
      metrics.update_all(latest_build_finished_at: pipeline.finished_at) if pipeline.success?
    end
  end
end
