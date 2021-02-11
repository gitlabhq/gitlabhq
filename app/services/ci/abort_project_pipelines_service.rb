# frozen_string_literal: true

module Ci
  class AbortProjectPipelinesService
    # Danger: Cancels in bulk without callbacks
    # Only for pipeline abandonment scenarios (current example: project delete)
    def execute(project)
      return unless Feature.enabled?(:abort_deleted_project_pipelines, default_enabled: :yaml)

      pipelines = project.all_pipelines.cancelable
      bulk_abort!(pipelines, status: :canceled)

      ServiceResponse.success(message: 'Pipelines canceled')
    end

    private

    def bulk_abort!(pipelines, status:)
      pipelines.each_batch do |pipeline_batch|
        CommitStatus.in_pipelines(pipeline_batch).in_batches.update_all(status: status) # rubocop: disable Cop/InBatches
        pipeline_batch.update_all(status: status)
      end
    end
  end
end
