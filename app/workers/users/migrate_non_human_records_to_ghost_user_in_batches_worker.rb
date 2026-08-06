# frozen_string_literal: true

module Users
  class MigrateNonHumanRecordsToGhostUserInBatchesWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- no single-resource context applies

    sidekiq_options retry: false
    feature_category :user_profile
    data_consistency :sticky
    idempotent!

    def perform
      # no-op in favor of Users::MigrateRecordsToGhostUserInBatchesWorker
      #
      # The worker is scheduled for removal by https://gitlab.com/gitlab-org/gitlab/-/work_items/607137
    end
  end
end
