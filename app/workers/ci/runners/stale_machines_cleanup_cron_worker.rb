# frozen_string_literal: true

module Ci
  module Runners
    class StaleMachinesCleanupCronWorker
      include ApplicationWorker

      # This worker does not schedule other workers that require context.
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :sticky
      feature_category :fleet_visibility
      urgency :low

      idempotent!

      def perform
        result = ::Ci::Runners::StaleManagersCleanupService.new.execute
        log_extra_metadata_on_done(:status, result.status)
        log_hash_metadata_on_done(result.payload)
      end
    end
  end
end
