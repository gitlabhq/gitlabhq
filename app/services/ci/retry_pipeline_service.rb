# frozen_string_literal: true

module Ci
  class RetryPipelineService < ::BaseService
    # Counted before the access check on purpose, per
    # https://gitlab.com/gitlab-org/gitlab/-/issues/627233: a rejected call is still a
    # call. The access response is returned first so the caller keeps the real reason.
    def execute(pipeline)
      throttled_response = check_rate_limit(pipeline)

      access_response = check_access(pipeline)
      return access_response if access_response.error?

      return throttled_response if throttled_response

      builds_relation(pipeline).find_each do |job|
        next unless can_be_retried?(job)

        Ci::RetryJobService.new(project, current_user).clone!(job)
      end

      pipeline.processables.latest.skipped.find_each do |skipped|
        Gitlab::OptimisticLocking.retry_lock(skipped, name: 'ci_retry_pipeline') do |job|
          job.process(current_user)
        end
      end

      pipeline.reset_source_bridge!(current_user)

      ::MergeRequests::AddTodoWhenBuildFailsService
        .new(project: project, current_user: current_user)
        .close_all(pipeline)

      pipeline.update(finished_at: nil)

      start_pipeline(pipeline)

      ServiceResponse.success
    rescue Gitlab::Access::AccessDeniedError => e
      ServiceResponse.error(message: e.message, http_status: :forbidden)
    rescue ActiveRecord::StaleObjectError
      ServiceResponse.error(message: 'Error updating stale job', http_status: :conflict)
    end

    def check_access(pipeline)
      if can?(current_user, :update_pipeline, pipeline)
        ServiceResponse.success
      else
        ServiceResponse.error(message: '403 Forbidden', http_status: :forbidden)
      end
    end

    private

    # Returns a throttled ServiceResponse, or nil when the call may proceed.
    def check_rate_limit(pipeline)
      return unless current_user
      return unless Feature.enabled?(:rate_limit_pipeline_retry, pipeline.project)
      return unless rate_limit_throttled?(pipeline)

      ServiceResponse.error(
        message: ::Gitlab::ApplicationRateLimiter.throttled_error_message,
        reason: :rate_limited,
        http_status: :too_many_requests
      )
    end

    # Short-circuited on purpose: a call already blocked per-pipeline must not consume the
    # per-project budget, or repeated retries of one pipeline would escalate into a
    # project-wide block. The per-project counter therefore tracks calls that did work.
    def rate_limit_throttled?(pipeline)
      ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_retry, scope: { user: current_user, ci_pipeline: pipeline }
      ) || ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_retry_per_project, scope: { user: current_user, project: pipeline.project }
      )
    end

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
