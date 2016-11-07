class PipelineUnlockWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::Pipeline.unfinished
      .where('updated_at < ?', 6.hours.ago)
      .find_each do |pipeline|
        PipelineProcessWorker.new.perform(pipeline.id)

        Gitlab::OptimisticLocking.retry_lock(pipeline) do |pipeline|
          pipeline.touch
        end
      end
  end
end
