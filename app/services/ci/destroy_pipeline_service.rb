# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      unsafe_execute([pipeline])
    end

    # In this we're intentionally grouping the operations in batches,
    # starting with the read queries, because we want to use the database
    # replica for as long as possible.
    # It is unsafe because the caller needs to ensure proper permissions check.
    def unsafe_execute(pipelines)
      expire_cache(pipelines)
      cancel_jobs(pipelines)
      reload_and_destroy(pipelines)

      ServiceResponse.success(message: 'Pipeline not found')
    end

    private

    def expire_cache(pipelines)
      Array.wrap(pipelines).each do |pipeline|
        ::Ci::ExpirePipelineCacheService.new.execute(pipeline, delete: true)
      end
    end

    # Ensure cancellation happens sync so we accumulate compute minutes
    # successfully before deleting the pipeline.
    def cancel_jobs(pipelines)
      Array.wrap(pipelines).each do |pipeline|
        ::Ci::CancelPipelineService.new(
          pipeline: pipeline,
          current_user: current_user,
          cascade_to_children: true,
          execute_async: false).force_execute
      end
    end

    def reload_and_destroy(pipelines)
      bulk_reload(Array.wrap(pipelines)).each do |pipeline|
        destroy_all_records(pipeline)
      end
    end

    def bulk_reload(pipelines)
      pipelines
        .group_by(&:partition_id)
        .transform_values { |pipelines| pipelines.map(&:id) }
        .map { |partition_id, ids| ::Ci::Pipeline.in_partition(partition_id).id_in(ids) }
        .reduce(:or)
        .to_a
    end

    # The pipeline, the builds, job and pipeline artifacts all get destroyed here.
    # Ci::Pipeline#destroy triggers fast destroy on job_artifacts and
    # build_trace_chunks to remove the records and data stored in object storage.
    # ci_builds records are deleted using ON DELETE CASCADE from ci_pipelines
    #
    def destroy_all_records(pipeline)
      pipeline.destroy!
    rescue ActiveRecord::StaleObjectError
      force_destroy_all_records(pipeline)
    end

    def force_destroy_all_records(pipeline)
      pipeline.reset.destroy!
    rescue ActiveRecord::RecordNotFound
      # concurrent destroy, carry on
    end
  end
end

Ci::DestroyPipelineService.prepend_mod
