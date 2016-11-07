class PipelineUnlockWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::Pipeline.unfinished
      .where('updated_at < ?', 6.hours.ago)
      .find_each do |pipeline|
        PipelineProcessWorker.new.perform(pipeline.id)
      end
  end
end
