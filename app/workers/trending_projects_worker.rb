# frozen_string_literal: true

class TrendingProjectsWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    Rails.logger.info('Refreshing trending projects') # rubocop:disable Gitlab/RailsLogger

    TrendingProject.refresh!
  end
end
