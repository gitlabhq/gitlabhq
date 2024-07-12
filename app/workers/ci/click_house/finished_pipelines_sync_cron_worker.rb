# frozen_string_literal: true

module Ci
  module ClickHouse
    class FinishedPipelinesSyncCronWorker
      include ApplicationWorker

      idempotent!
      queue_namespace :cronjob
      data_consistency :delayed
      feature_category :fleet_visibility
      loggable_arguments 1

      def perform(*args)
        return unless ::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService.enabled?

        total_workers = args.first || 1

        total_workers.times do |worker_index|
          FinishedPipelinesSyncWorker.perform_async(worker_index, total_workers)
        end

        nil
      end
    end
  end
end
