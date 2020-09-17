# frozen_string_literal: true

module Ci
  class RetryPipelineService < ::BaseService
    include Gitlab::OptimisticLocking

    def execute(pipeline)
      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      needs = Set.new

      pipeline.ensure_scheduling_type!

      pipeline.retryable_builds.preload_needs.find_each do |build|
        next unless can?(current_user, :update_build, build)

        Ci::RetryBuildService.new(project, current_user)
          .reprocess!(build)

        needs += build.needs.map(&:name)
      end

      pipeline.builds.latest.skipped.find_each do |skipped|
        retry_optimistic_lock(skipped) { |build| build.process }
      end

      pipeline.reset_ancestor_bridges!

      MergeRequests::AddTodoWhenBuildFailsService
        .new(project, current_user)
        .close_all(pipeline)

      Ci::ProcessPipelineService
        .new(pipeline)
        .execute
    end
  end
end
