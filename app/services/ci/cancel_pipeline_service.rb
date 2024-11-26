# frozen_string_literal: true

module Ci
  # Cancel a pipelines cancelable jobs and optionally it's child pipelines cancelable jobs
  class CancelPipelineService
    include Gitlab::OptimisticLocking
    include Gitlab::Allowable

    ##
    # @cascade_to_children - if true cancels all related child pipelines for parent child pipelines
    # @auto_canceled_by_pipeline - store the pipeline_id of the pipeline that triggered cancellation
    # @execute_async - if true cancel the children asyncronously
    # @safe_cancellation - if true only cancel interruptible:true jobs
    def initialize(
      pipeline:,
      current_user:,
      cascade_to_children: true,
      auto_canceled_by_pipeline: nil,
      execute_async: true,
      safe_cancellation: false)
      @pipeline = pipeline
      @current_user = current_user
      @cascade_to_children = cascade_to_children
      @auto_canceled_by_pipeline = auto_canceled_by_pipeline
      @execute_async = execute_async
      @safe_cancellation = safe_cancellation
    end

    def execute
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
        cancel_jobs(pipeline.processables.cancelable.interruptible)
      else
        cancel_jobs(pipeline.cancelable_statuses)
      end

      cancel_children if cascade_to_children?

      ServiceResponse.success
    end

    private

    attr_reader :pipeline, :current_user, :auto_canceled_by_pipeline

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

    def cancel_jobs(jobs)
      retries = 3
      retry_lock(jobs, retries, name: 'ci_pipeline_cancel_running') do |jobs_to_cancel|
        preloaded_relations = [:project, :pipeline, :deployment, :taggings]

        jobs_to_cancel.find_in_batches do |batch|
          relation = CommitStatus.id_in(batch)
          Preloaders::CommitStatusPreloader.new(relation).execute(preloaded_relations)

          relation.each { |job| cancel_job(job) }
        end
      end
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
