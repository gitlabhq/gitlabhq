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

      builds_relation(pipeline).find_each do |build|
        next unless can_be_retried?(build)

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

    private

    def builds_relation(pipeline)
      pipeline.retryable_builds.preload_needs
    end

    def can_be_retried?(build)
      can?(current_user, :update_build, build)
    end
  end
end

Ci::RetryPipelineService.prepend_mod_with('Ci::RetryPipelineService')
