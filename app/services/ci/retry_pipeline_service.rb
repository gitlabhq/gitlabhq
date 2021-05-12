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
        retry_optimistic_lock(skipped, name: 'ci_retry_pipeline') { |build| build.process(current_user) }
      end

      pipeline.reset_source_bridge!(current_user)

      ::MergeRequests::AddTodoWhenBuildFailsService
        .new(project: project, current_user: current_user)
        .close_all(pipeline)

      Ci::ProcessPipelineService
        .new(pipeline)
        .execute
    end
  end
end
