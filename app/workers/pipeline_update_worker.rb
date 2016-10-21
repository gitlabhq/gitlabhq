class PipelineUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(pipeline_id)
    Gitlab::Worker::Unique.new(self.class, pipeline_id).release!

    Ci::Pipeline.find_by(id: pipeline_id).try(:update_status)
  end
end
