# frozen_string_literal: true

module Users
  class MigrateRecordsToGhostUserInBatchesWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :user_profile
    data_consistency :sticky
    idempotent!

    def perform
      in_lock(self.class.name.underscore, ttl: Gitlab::Utils::ExecutionTracker::MAX_RUNTIME, retries: 0) do
        Users::MigrateRecordsToGhostUserInBatchesService.new(user_types: user_types_for_processing).execute
      end
    end

    private

    def user_types_for_processing
      HasUserType::USER_TYPES.keys - [
        'human' # Processed separately by Users::MigrateHumanRecordsToGhostUserInBatchesWorker
      ]
    end
  end
end
