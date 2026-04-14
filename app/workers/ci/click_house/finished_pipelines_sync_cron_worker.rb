# frozen_string_literal: true

module Ci
  module ClickHouse
    class FinishedPipelinesSyncCronWorker
      include ApplicationWorker

      idempotent!
      queue_namespace :cronjob
      data_consistency :delayed
      feature_category :fleet_visibility
      tags :clickhouse
      loggable_arguments 1

      MEDIUM_WORKERS = 3
      HIGH_WORKERS = 5

      def perform(*args)
        return unless ::Ci::ClickHouse::DataIngestion::FinishedPipelinesSyncService.enabled?

        total_workers = worker_count(args)

        total_workers.times do |worker_index|
          FinishedPipelinesSyncWorker.perform_async(worker_index, total_workers)
        end

        nil
      end

      private

      def worker_count(args)
        if Feature.enabled?(:ci_finished_pipelines_sync_high_workers, :instance, type: :ops)
          HIGH_WORKERS
        elsif Feature.enabled?(:ci_finished_pipelines_sync_medium_workers, :instance, type: :ops)
          MEDIUM_WORKERS
        else
          args.first || 1
        end
      end
    end
  end
end
