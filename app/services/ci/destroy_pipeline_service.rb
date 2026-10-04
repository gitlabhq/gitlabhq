# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    # Counted before the permission check on purpose, per
    # https://gitlab.com/gitlab-org/gitlab/-/issues/627268: a rejected call is still a call.
    # The permission error is raised first so the caller keeps the real reason.
    #
    # Only #execute is throttled. Housekeeping, project deletion and batch issuable deletion
    # call #unsafe_execute, which stays unlimited.
    def execute(pipeline)
      throttled_response = check_rate_limit(pipeline)

      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      return throttled_response if throttled_response

      unsafe_execute([pipeline])
    end

    # In this we're intentionally grouping the operations in batches,
    # starting with the read queries, because we want to use the database
    # replica for as long as possible.
    # It is unsafe because the caller needs to ensure proper permissions check.
    #
    # @param [<Array>Ci::Pipeline] pipelines
    # @param [Boolean] skip_cancel - skips canceling the pipeline before destroy.
    #   Only to be used when deleting old pipelines and  we don't care about
    #   triggering side effects like, counting CI minutes, email notifications, etc.
    #   It should not be used with `execute` because for user-triggered deletions
    #   we always want side effects to be triggered.
    def unsafe_execute(pipelines, skip_cancel: false)
      expire_cache(pipelines)
      cancel_jobs(pipelines) unless skip_cancel
      reload_and_destroy(pipelines)

      ServiceResponse.success(message: 'Pipeline not found')
    end

    private

    def check_rate_limit(pipeline)
      return unless current_user
      return unless Feature.enabled?(:rate_limit_pipeline_delete, pipeline.project)

      limit = throttled_limit(pipeline)
      return unless limit

      log_rate_limited(pipeline, limit)

      ServiceResponse.error(
        message: ::Gitlab::ApplicationRateLimiter.throttled_error_message,
        reason: :rate_limited
      )
    end

    # Returns the key of the limit that fired, or nil. Short-circuited on purpose: a call
    # already blocked per-pipeline must not consume the per-project budget, or repeated
    # deletes of one pipeline would escalate into a project-wide block.
    def throttled_limit(pipeline)
      return :pipeline_delete if ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_delete, scope: { user: current_user, ci_pipeline: pipeline }
      )

      return :pipeline_delete_per_project if ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_delete_per_project, scope: { user: current_user, project: pipeline.project }
      )

      nil
    end

    def log_rate_limited(pipeline, limit)
      Gitlab::AppJsonLogger.info(
        Labkit::Fields::CLASS_NAME => self.class.to_s,
        message: 'Pipeline delete rate limit exceeded',
        rate_limit: limit.to_s,
        Labkit::Fields::GL_PROJECT_ID => pipeline.project_id,
        Labkit::Fields::GL_PIPELINE_ID => pipeline.id,
        Labkit::Fields::GL_USER_ID => current_user.id,
        **Gitlab::ApplicationContext.current
      )
    end

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
