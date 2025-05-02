# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class AggregateLast30DayUsageWorker
        include ApplicationWorker
        include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- Periodic processing is required

        MAX_RUNTIME = 4.minutes # Should be >= job scheduling frequency so there is no gap between job runs

        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155001#note_1941066672
        # Includes extra time (1.minute) to execute `&usage_counts_block`
        WORKER_DEDUP_TTL = MAX_RUNTIME + 1.minute

        feature_category :pipeline_composition

        data_consistency :sticky
        urgency :low
        idempotent!

        deduplicate :until_executed, if_deduplicated: :reschedule_once,
          ttl: WORKER_DEDUP_TTL

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
