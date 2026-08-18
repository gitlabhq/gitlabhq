# frozen_string_literal: true

module Notifications
  module MobilePush
    class PruneStaleSubscriptionsWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- instance-wide cleanup, no meaningful context

      idempotent!
      data_consistency :sticky
      feature_category :notifications
      defer_on_database_health_signal :gitlab_main, [:mobile_device_push_subscriptions], 5.minutes

      STALE_AFTER = 90.days
      BATCH_SIZE = 1_000

      def perform
        cutoff = STALE_AFTER.ago
        deleted_count = 0

        MobileDevicePushSubscription.stale(cutoff).each_batch(of: BATCH_SIZE) do |batch|
          deleted_count += batch.delete_all
        end

        log_extra_metadata_on_done(:deleted_count, deleted_count)
        log_extra_metadata_on_done(:cutoff, cutoff.iso8601)
      end
    end
  end
end
