# frozen_string_literal: true

module Ci
  module StuckPipelines
    class ProcessService
      STUCK_THRESHOLD = 5.minutes
      LOOKBACK_WINDOW = 1.hour
      BATCH_SIZE = 100
      MAX_PIPELINES = 2_000

      def execute
        return unless Feature.enabled?(:ci_process_stuck_pipelines, :instance)

        total_processed = 0

        Ci::Partition.find_each do |partition|
          iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: stale_running_pipelines(partition))

          iterator.each_batch(of: BATCH_SIZE) do |batch|
            stuck_ids = stuck_pipeline_ids(partition, batch)

            stuck_ids.each do |pipeline_id|
              process_pipeline(pipeline_id)
            end

            total_processed += stuck_ids.size

            break if processed_over_limit?(total_processed)
          end

          break if processed_over_limit?(total_processed)
        end

        return unless processed_over_limit?(total_processed)

        Gitlab::AppLogger.warn(
          class_name: self.class.name,
          message: "Stuck pipelines cap reached, remaining pipelines will be processed in the next run",
          total_processed: total_processed,
          cap: MAX_PIPELINES
        )
      end

      private

      def process_pipeline(id)
        Gitlab::AppLogger.info(message: 'Reprocessing stuck pipeline', pipeline_id: id)

        PipelineProcessWorker.perform_async(id)
      end

      def processed_over_limit?(processed)
        processed >= MAX_PIPELINES
      end

      def stale_running_pipelines(partition)
        Ci::Pipeline
          .running
          .in_partition(partition.id)
          .updated_before(STUCK_THRESHOLD.ago)
          .updated_after(LOOKBACK_WINDOW.ago)
          .order_updated_at_asc_id_asc
      end

      def stuck_pipeline_ids(partition, batch)
        cte = Gitlab::SQL::CTE.new(:stuck_pipelines_batch, batch)

        cte.apply_to(Ci::Pipeline.all).without_active_builds(partition.id).pluck_primary_key
      end
    end
  end
end
