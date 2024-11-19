# frozen_string_literal: true

module Users
  class CreateStatisticsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :user_profile

    def perform
      UsersStatistics.create_current_stats!
    rescue ActiveRecord::RecordInvalid => exception
      Gitlab::ErrorTracking.track_exception(exception)
    end
  end
end
