class TrendingProjectsWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Rails.logger.info('Refreshing trending projects')

    TrendingProject.refresh!
  end
end
