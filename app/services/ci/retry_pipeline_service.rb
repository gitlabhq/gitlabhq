# frozen_string_literal: true

module Ci
  class RetryPipelineService < ::BaseService
    include Gitlab::OptimisticLocking

    def execute(pipeline)
      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      needs = Set.new

      pipeline.retryable_builds.preload_needs.find_each do |build|
        next unless can?(current_user, :update_build, build)

        Ci::RetryBuildService.new(project, current_user)
          .reprocess!(build)

        needs += build.needs.map(&:name)
      end

      # In a DAG, the dependencies may have already completed. Figure out
      # which builds have succeeded and use them to update the pipeline. If we don't
      # do this, then builds will be stuck in the created state since their dependencies
      # will never run.
      completed_build_ids = pipeline.find_successful_build_ids_by_names(needs) if needs.any?

      pipeline.builds.latest.skipped.find_each do |skipped|
        retry_optimistic_lock(skipped) { |build| build.process }
      end

      MergeRequests::AddTodoWhenBuildFailsService
        .new(project, current_user)
        .close_all(pipeline)

      Ci::ProcessPipelineService
        .new(pipeline)
        .execute(completed_build_ids)
    end
  end
end
