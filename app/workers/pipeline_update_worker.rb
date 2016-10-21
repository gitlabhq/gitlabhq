class PipelineUpdateWorker
  include Sidekiq::Worker
  include Gitlab::Worker::Unique

  sidekiq_options queue: :default

  def perform(pipeline_id)
    unique_processing(pipeline_id) do
      Ci::Pipeline.find_by(id: pipeline_id)
        .try(:update_status)
    end
  end
end
