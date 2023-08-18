# frozen_string_literal: true

module ClickHouse
  class EventsSyncWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    idempotent!
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    # the job is scheduled every 3 minutes and we will allow maximum 2.5 minutes runtime
    MAX_TTL = 2.5.minutes.to_i

    def perform
      unless enabled?
        log_extra_metadata_on_done(:result, { status: :disabled })

        return
      end

      metadata = { status: :processed }

      # Prevent parallel jobs
      begin
        in_lock(self.class.to_s, ttl: MAX_TTL, retries: 0) do
          true
        end

      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        # Skip retrying, just let the next worker to start after a few minutes
        metadata = { status: :skipped }
      end

      log_extra_metadata_on_done(:result, metadata)
    end

    private

    def enabled?
      ClickHouse::Client.configuration.databases[:main].present? && Feature.enabled?(:event_sync_worker_for_click_house)
    end
  end
end
