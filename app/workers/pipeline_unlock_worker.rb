class PipelineUnlockWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::Pipeline.unfinished.with_builds
      .where('ci_commits.updated_at < ?', 6.hours.ago)
      .where('ci_commits.created_at > ?', 1.week.ago)
      .select(:id)
      .find_each do |pipeline|
        PipelineProcessWorker.perform_async(pipeline.id)
      end
  end
end
