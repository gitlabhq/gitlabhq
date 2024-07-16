# frozen_string_literal: true

module Ci
  module ClickHouse
    class FinishedPipelinesSyncWorker
      include ApplicationWorker
      include ClickHouseWorker

      idempotent!
      data_consistency :delayed
      urgency :throttled
      feature_category :fleet_visibility
      loggable_arguments 1, 2

      def perform(worker_index = 0, total_workers = 1)
        response = ::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService.new(
          worker_index: worker_index, total_workers: total_workers
        ).execute

        result = response.success? ? response.payload : response.deconstruct_keys(%i[message reason])
        log_extra_metadata_on_done(:result, result)
      end
    end
  end
end
