# frozen_string_literal: true

module Ci
  class RetryPipelineService < ::BaseService
    # TTL for the Redis lease held while one pipeline retry runs. 1 minute matches the
    # Rack request timeout, so the REST API path never needs longer. A lease that
    # expires just lets retries overlap, as before this lock.
    LOCK_TIMEOUT = 1.minute

    # Counted before the access check on purpose, per
    # https://gitlab.com/gitlab-org/gitlab/-/issues/627233: a rejected call is still a
    # call. The access response is returned first so the caller keeps the real reason.
    def execute(pipeline)
      throttled_response = check_rate_limit(pipeline)

      access_response = check_access(pipeline)
      return access_response if access_response.error?

      return throttled_response if throttled_response

      retry_jobs_exclusively(pipeline)
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

    # Non-waiting on purpose: a concurrent retry of the same pipeline cannot do useful
    # work until the first one finishes, so it is rejected rather than queued behind
    # the lock and tying up a web thread.
    def retry_jobs_exclusively(pipeline)
      return retry_jobs(pipeline) unless Feature.enabled?(:lock_concurrent_pipeline_retries, pipeline.project)

      key = lock_key(pipeline)
      uuid = Gitlab::ExclusiveLease.new(key, timeout: LOCK_TIMEOUT).try_obtain
      return retry_in_progress_response unless uuid

      begin
        retry_jobs(pipeline)
      ensure
        Gitlab::ExclusiveLease.cancel(key, uuid)
      end
    end

    def retry_in_progress_response
      ServiceResponse.error(
        message: 'Pipeline is already being retried',
        reason: :retry_in_progress,
        http_status: :conflict
      )
    end

    def retry_jobs(pipeline)
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
    end

    def lock_key(pipeline)
      "ci:retry_pipeline_service:lock:#{pipeline.id}"
    end

    # Returns a throttled ServiceResponse, or nil when the call may proceed.
    def check_rate_limit(pipeline)
      return unless current_user
      return unless Feature.enabled?(:rate_limit_pipeline_retry, pipeline.project)

      limit = throttled_limit(pipeline)
      return unless limit

      log_rate_limited(pipeline, limit)

      ServiceResponse.error(
        message: ::Gitlab::ApplicationRateLimiter.throttled_error_message,
        reason: :rate_limited,
        http_status: :too_many_requests
      )
    end

    # Returns the key of the limit that fired, or nil. Short-circuited on purpose: a call
    # already blocked per-pipeline must not consume the per-project budget, or repeated
    # retries of one pipeline would escalate into a project-wide block.
    def throttled_limit(pipeline)
      return :pipeline_retry if ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_retry, scope: { user: current_user, ci_pipeline: pipeline }
      )

      return :pipeline_retry_per_project if ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_retry_per_project, scope: { user: current_user, project: pipeline.project }
      )

      nil
    end

    def log_rate_limited(pipeline, limit)
      Gitlab::AppJsonLogger.info(
        Labkit::Fields::CLASS_NAME => self.class.to_s,
        message: 'Pipeline retry rate limit exceeded',
        rate_limit: limit.to_s,
        Labkit::Fields::GL_PROJECT_ID => pipeline.project_id,
        Labkit::Fields::GL_PIPELINE_ID => pipeline.id,
        Labkit::Fields::GL_USER_ID => current_user.id,
        **Gitlab::ApplicationContext.current
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
