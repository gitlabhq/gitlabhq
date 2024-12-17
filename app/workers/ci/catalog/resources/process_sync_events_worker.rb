# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This worker can be called multiple times simultaneously but only one can process events
      # at a time. This is ensured by `try_obtain_lease` in `Ci::ProcessSyncEventsService`.
      #
      # This worker is enqueued in 3 ways:
      # 1. By Project model callback after updating one of the columns referenced in
      #    `Ci::Catalog::Resource#sync_with_project`.
      # 2. Every minute by cron job. This ensures we process SyncEvents from direct/bulk
      #    database updates that do not use the Project AR model.
      # 3. By `Ci::ProcessSyncEventsService` if there are any remaining pending
      #    SyncEvents after processing.
      #
      class ProcessSyncEventsWorker
        include ApplicationWorker
        include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- Periodic processing is required

        feature_category :pipeline_composition

        data_consistency :sticky
        urgency :high

        idempotent!
        deduplicate :until_executed, if_deduplicated: :reschedule_once, ttl: 1.minute

        def perform
          results = ::Ci::ProcessSyncEventsService.new(
            ::Ci::Catalog::Resources::SyncEvent, ::Ci::Catalog::Resource
          ).execute

          results.each do |key, value|
            log_extra_metadata_on_done(key, value)
          end
        end
      end
    end
  end
end
