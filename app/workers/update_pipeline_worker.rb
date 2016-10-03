class UpdatePipelineWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)
    return unless pipeline

    pipeline.update_status
  end
end
