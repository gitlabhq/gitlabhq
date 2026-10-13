# frozen_string_literal: true

module Ci
  module RedundantPipelines
    # Records that a build which cannot be interrupted has started, so its pipeline
    # is no longer auto-canceled by a newer one.
    class ProtectPipelineWorker
      include ApplicationWorker
      include PipelineBackgroundQueue

      data_consistency :sticky
      urgency :low
      idempotent!
      deduplicate :until_executed
      loggable_arguments 0, 1
      defer_on_database_health_signal :gitlab_ci, [:p_ci_pipeline_processing_data], 1.minute

      def perform(pipeline_id, partition_id)
        ::Ci::Pipeline.find_by_id_and_partition(pipeline_id, partition_id).try do |pipeline|
          ::Ci::PipelineProcessingData.protect(pipeline)
        end
      end
    end
  end
end
