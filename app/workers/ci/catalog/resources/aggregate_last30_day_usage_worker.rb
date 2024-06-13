# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This worker can be called multiple times simultaneously but only one can process data at a time.
      # This is ensured by an exclusive lease guard in `Gitlab::Ci::Components::Usages::Aggregator`.
      # The scheduling frequency should be == `Gitlab::Ci::Components::Usages::Aggregator::MAX_RUNTIME`
      # so there is no time gap between job runs.
      class AggregateLast30DayUsageWorker
        include ApplicationWorker
        include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- Periodic processing is required

        feature_category :pipeline_composition

        data_consistency :sticky
        urgency :low
        idempotent!

        deduplicate :until_executed, if_deduplicated: :reschedule_once,
          ttl: Gitlab::Ci::Components::Usages::Aggregator::WORKER_DEDUP_TTL

        def perform
          response = Ci::Catalog::Resources::AggregateLast30DayUsageService.new.execute

          log_hash_metadata_on_done(
            status: response.status,
            message: response.message,
            **response.payload
          )
        end
      end
    end
  end
end
