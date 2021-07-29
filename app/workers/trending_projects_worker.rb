# frozen_string_literal: true

class TrendingProjectsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    Gitlab::AppLogger.info('Refreshing trending projects')

    TrendingProject.refresh!
  end
end
