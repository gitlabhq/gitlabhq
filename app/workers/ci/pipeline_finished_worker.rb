# frozen_string_literal: true

module Ci
  class PipelineFinishedWorker
    include ApplicationWorker
    include PipelineQueue

    data_consistency :sticky

    queue_namespace :pipeline_processing
    urgency :low
    idempotent!
    worker_resource_boundary :cpu

    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)

      return unless pipeline
      return unless pipeline.project
      return if pipeline.project.pending_delete?

      process_pipeline(pipeline)
    end

    private

    # Processes a single CI pipeline that has finished.
    #
    # @param [Ci::Pipeline] pipeline The pipeline to process.
    def process_pipeline(pipeline)
      return unless finished_pipeline_sync_event?(pipeline)

      # Use upsert since this code can be called more than once for the same pipeline
      ::Ci::FinishedPipelineChSyncEvent.upsert(
        {
          pipeline_id: pipeline.id,
          pipeline_finished_at: pipeline.finished_at,
          project_namespace_id: pipeline.project.project_namespace_id
        },
        unique_by: [:pipeline_id, :partition]
      )
    end

    def finished_pipeline_sync_event?(pipeline)
      pipeline.finished_at.present?
    end
  end
end
