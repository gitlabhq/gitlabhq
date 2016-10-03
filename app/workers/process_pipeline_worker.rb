class ProcessPipelineWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(pipeline_id, params)
    begin
      pipeline = Ci::Pipeline.find(pipeline_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    pipeline.process! if params['process']

    pipeline.update_status
  end
end
