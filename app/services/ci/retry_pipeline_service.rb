# frozen_string_literal: true

module Ci
  class RetryPipelineService < ::BaseService
    include Gitlab::OptimisticLocking

    def execute(pipeline)
      access_response = check_access(pipeline)
      return access_response if access_response.error?

      pipeline.ensure_scheduling_type!

      builds_relation(pipeline).find_each do |job|
        next unless can_be_retried?(job)

        Ci::RetryJobService.new(project, current_user).clone!(job)
      end

      pipeline.processables.latest.skipped.find_each do |skipped|
        retry_optimistic_lock(skipped, name: 'ci_retry_pipeline') { |job| job.process(current_user) }
      end

      pipeline.reset_source_bridge!(current_user)

      ::MergeRequests::AddTodoWhenBuildFailsService
        .new(project: project, current_user: current_user)
        .close_all(pipeline)

      start_pipeline(pipeline)

      ServiceResponse.success
    rescue Gitlab::Access::AccessDeniedError => e
      ServiceResponse.error(message: e.message, http_status: :forbidden)
    end

    def check_access(pipeline)
      if can?(current_user, :update_pipeline, pipeline)
        ServiceResponse.success
      else
        ServiceResponse.error(message: '403 Forbidden', http_status: :forbidden)
      end
    end

    private

    def builds_relation(pipeline)
      pipeline.retryable_builds.preload_needs.preload_job_definition_instances
    end

    def can_be_retried?(job)
      can?(current_user, :retry_job, job) && job.retryable?
    end

    def start_pipeline(pipeline)
      Ci::PipelineCreation::StartPipelineService.new(pipeline).execute
    end
  end
end

Ci::RetryPipelineService.prepend_mod_with('Ci::RetryPipelineService')
