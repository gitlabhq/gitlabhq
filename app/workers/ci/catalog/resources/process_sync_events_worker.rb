# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This worker can be called multiple times simultaneously but only one can process events
      # at a time. This is ensured by `try_obtain_lease` in `Ci::ProcessSyncEventsService`.
      class ProcessSyncEventsWorker
        include ApplicationWorker

        feature_category :pipeline_composition

        data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- We should not sync stale data
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
