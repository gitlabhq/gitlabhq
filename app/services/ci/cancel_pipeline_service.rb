# frozen_string_literal: true

module Ci
  # Cancel a pipelines cancelable jobs and optionally it's child pipelines cancelable jobs
  class CancelPipelineService
    include Gitlab::Allowable

    ##
    # @cascade_to_children - if true cancels all related child pipelines for parent child pipelines
    # @auto_canceled_by_pipeline - store the pipeline_id of the pipeline that triggered cancellation
    # @execute_async - if true cancel the children asyncronously
    # @safe_cancellation - if true only cancel interruptible:true jobs
    # @rate_limit - if true apply the per-user rate limits; set to false for internal
    #   callers such as Ci::UserCancelPipelineWorker that must never be throttled
    def initialize(
      pipeline:,
      current_user:,
      cascade_to_children: true,
      auto_canceled_by_pipeline: nil,
      execute_async: true,
      safe_cancellation: false,
      rate_limit: true)
      @pipeline = pipeline
      @current_user = current_user
      @cascade_to_children = cascade_to_children
      @auto_canceled_by_pipeline = auto_canceled_by_pipeline
      @execute_async = execute_async
      @safe_cancellation = safe_cancellation
      @rate_limit = rate_limit
    end

    def execute
      throttled_response = rate_limited_response
      return throttled_response if throttled_response

      return permission_error_response unless can?(current_user, :cancel_pipeline, pipeline)

      force_execute
    end

    # This method should be used only when we want to always cancel the pipeline without
    # checking whether the current_user has permissions to do so, or when we don't have
    # a current_user available in the context.
    def force_execute
      return ServiceResponse.error(message: 'No pipeline provided', reason: :no_pipeline) unless pipeline

      unless pipeline.cancelable?
        return ServiceResponse.error(message: 'Pipeline is not cancelable', reason: :pipeline_not_cancelable)
      end

      log_pipeline_being_canceled
      update_auto_canceled_pipeline_attributes

      if @safe_cancellation
        # Only build and bridge (trigger) jobs can be interruptible.
        # We do not cancel GenericCommitStatuses because they can't have the `interruptible` attribute.
        jobs = pipeline.processables.cancelable.with_interruptible_true

        cancel_jobs(jobs)
      else
        cancel_jobs(pipeline.cancelable_statuses)
      end

      cancel_children if cascade_to_children?

      ServiceResponse.success
    end

    private

    attr_reader :pipeline, :current_user, :auto_canceled_by_pipeline

    # Every call that reaches the service with a user is counted, before the permission
    # and cancelable? checks: a rejected or no-op cancel still costs a request, and counting
    # it is what stops a caller from looping on it. Internal callers pass rate_limit: false.
    def rate_limited_response
      return unless @rate_limit && current_user && pipeline
      return unless Feature.enabled?(:rate_limit_pipeline_cancel, pipeline.project)
      return unless rate_limit_throttled?

      log_rate_limited

      ServiceResponse.error(
        message: ::Gitlab::ApplicationRateLimiter.throttled_error_message,
        reason: :rate_limited
      )
    end

    def log_rate_limited
      Gitlab::AppJsonLogger.info(
        class: self.class.to_s,
        message: 'Pipeline cancel rate limit exceeded',
        project_id: pipeline.project_id,
        pipeline_id: pipeline.id,
        Labkit::Fields::GL_USER_ID => current_user.id,
        **Gitlab::ApplicationContext.current
      )
    end

    def rate_limit_throttled?
      # Short-circuit on the per-pipeline limit so an already-blocked caller does not
      # keep consuming the per-project budget: hammering Cancel on one pipeline must
      # not lock the whole project's other pipelines out of cancellation.
      return true if ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_cancel, scope: { user: current_user, ci_pipeline: pipeline }
      )

      ::Gitlab::ApplicationRateLimiter.throttled?(
        :pipeline_cancel_per_project, scope: { user: current_user, project: pipeline.project }
      )
    end

    def log_pipeline_being_canceled
      Gitlab::AppJsonLogger.info(
        class: self.class.to_s,
        event: 'pipeline_cancel_running',
        pipeline_id: pipeline.id,
        auto_canceled_by_pipeline_id: @auto_canceled_by_pipeline&.id,
        cascade_to_children: cascade_to_children?,
        execute_async: execute_async?,
        **Gitlab::ApplicationContext.current
      )
    end

    def update_auto_canceled_pipeline_attributes
      return unless auto_canceled_by_pipeline

      pipeline.update_columns(
        auto_canceled_by_id: auto_canceled_by_pipeline.id,
        auto_canceled_by_partition_id: auto_canceled_by_pipeline.partition_id
      )
    end

    def cascade_to_children?
      @cascade_to_children
    end

    def execute_async?
      @execute_async
    end

    def cancel_jobs(cancelable_jobs)
      cancelable_jobs.each_batch(of: 50) do |batch_relation|
        ::Ci::Preloaders::CommitStatusPreloader
          .new(batch_relation).execute(build_preloads)

        batch_relation.each do |job|
          Gitlab::OptimisticLocking.retry_lock(job,
            name: 'ci_pipeline_cancel_running') do |subject|
            cancel_job(subject)
          end
        end
      end
    end

    def build_preloads
      [:project, :pipeline, :deployment, :pending_state, :job_definition_instance, :job_definition]
    end

    def cancel_job(job)
      if @auto_canceled_by_pipeline
        job.auto_canceled_by_id = @auto_canceled_by_pipeline.id
        job.auto_canceled_by_partition_id = @auto_canceled_by_pipeline.partition_id
      end

      job.cancel
    end

    def permission_error_response
      ServiceResponse.error(
        message: 'Insufficient permissions to cancel the pipeline',
        reason: :insufficient_permissions
      )
    end

    # We don't handle the case when `cascade_to_children` is `true` and `safe_cancellation` is `true`
    # because `safe_cancellation` is passed as `true` only when `cascade_to_children` is `false`
    # from `CancelRedundantPipelinesService`.
    # In the future, when "safe cancellation" is implemented as a regular cancellation feature,
    # we need to handle this case.
    def cancel_children
      cancel_jobs(pipeline.bridges_in_self_and_project_descendants.cancelable)

      # For parent child-pipelines only (not multi-project)
      pipeline.all_child_pipelines.each do |child_pipeline|
        if execute_async?
          ::Ci::CancelPipelineWorker.perform_async(
            child_pipeline.id,
            @auto_canceled_by_pipeline&.id
          )
        else
          # cascade_to_children is false because we iterate through children
          # we also cancel bridges prior to prevent more children
          self.class.new(
            pipeline: child_pipeline.reset,
            current_user: nil,
            cascade_to_children: false,
            execute_async: execute_async?,
            auto_canceled_by_pipeline: @auto_canceled_by_pipeline
          ).force_execute
        end
      end
    end
  end
end
