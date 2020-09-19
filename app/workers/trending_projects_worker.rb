# frozen_string_literal: true

class TrendingProjectsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    Gitlab::AppLogger.info('Refreshing trending projects')

    TrendingProject.refresh!
  end
end
