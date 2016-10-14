class TrendingProjectsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :trending_projects

  def perform
    Rails.logger.info('Refreshing trending projects')

    TrendingProject.refresh!
  end
end
