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
      return unless Feature.enabled?(:split_ghost_user_migration_queue_into_human_and_non_human, :instance)

      in_lock(self.class.name.underscore, ttl: Gitlab::Utils::ExecutionTracker::MAX_RUNTIME, retries: 0) do
        Users::MigrateUserTypeRecordsToGhostUserInBatchesService.new(user_type: :non_human).execute
      end
    end
  end
end
