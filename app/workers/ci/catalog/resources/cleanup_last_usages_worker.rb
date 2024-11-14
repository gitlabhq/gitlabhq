# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class CleanupLastUsagesWorker
        include ApplicationWorker
        include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- Periodic processing is required

        feature_category :pipeline_composition

        data_consistency :sticky
        urgency :low
        idempotent!

        def perform
          Ci::Catalog::Resources::Components::LastUsage.older_than_30_days.each_batch(of: 1000) do |batch|
            batch.delete_all
          end
        end
      end
    end
  end
end
