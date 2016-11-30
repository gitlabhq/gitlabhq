class PipelineUnlockWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Ci::Pipeline.unfinished.with_builds
      .where('ci_commits.updated_at < ?', 6.hours.ago)
      .where('ci_commits.created_at > ?', 1.week.ago)
      .order(:id).pluck(:id).tap do |ids|
        break if ids.empty?

        Sidekiq::Client.push_bulk('class' => PipelineProcessWorker,
                                  'args' => ids.in_groups_of(1))
      end
  end
end
