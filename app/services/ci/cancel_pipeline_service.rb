# frozen_string_literal: true

module Ci
  # Cancel a pipelines cancelable jobs and optionally it's child pipelines cancelable jobs
  class CancelPipelineService
    include Gitlab::OptimisticLocking
    include Gitlab::Allowable

    ##
    # @cascade_to_children - if true cancels all related child pipelines for parent child pipelines
    # @auto_canceled_by_pipeline_id - store the pipeline_id of the pipeline that triggered cancellation
    # @execute_async - if true cancel the children asyncronously
    def initialize(
      pipeline:,
      current_user:,
      cascade_to_children: true,
      auto_canceled_by_pipeline_id: nil,
      execute_async: true)
      @pipeline = pipeline
      @current_user = current_user
      @cascade_to_children = cascade_to_children
      @auto_canceled_by_pipeline_id = auto_canceled_by_pipeline_id
      @execute_async = execute_async
    end

    def execute
      unless can?(current_user, :update_pipeline, pipeline)
        return ServiceResponse.error(
          message: 'Insufficient permissions to cancel the pipeline',
          reason: :insufficient_permissions)
      end

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

      pipeline.update_column(:auto_canceled_by_id, @auto_canceled_by_pipeline_id) if @auto_canceled_by_pipeline_id
      cancel_jobs(pipeline.cancelable_statuses)

      return ServiceResponse.success unless cascade_to_children?

      # cancel any bridges that could spin up new child pipelines
      cancel_jobs(pipeline.bridges_in_self_and_project_descendants.cancelable)
      cancel_children

      ServiceResponse.success
    end

    private

    attr_reader :pipeline, :current_user

    def log_pipeline_being_canceled
      Gitlab::AppJsonLogger.info(
        event: 'pipeline_cancel_running',
        pipeline_id: pipeline.id,
        auto_canceled_by_pipeline_id: @auto_canceled_by_pipeline_id,
        cascade_to_children: cascade_to_children?,
        execute_async: execute_async?,
        **Gitlab::ApplicationContext.current
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

          relation.each do |job|
            job.auto_canceled_by_id = @auto_canceled_by_pipeline_id if @auto_canceled_by_pipeline_id
            job.cancel
          end
        end
      end
    end

    # For parent child-pipelines only (not multi-project)
    def cancel_children
      pipeline.all_child_pipelines.each do |child_pipeline|
        if execute_async?
          ::Ci::CancelPipelineWorker.perform_async(
            child_pipeline.id,
            @auto_canceled_by_pipeline_id
          )
        else
          # cascade_to_children is false because we iterate through children
          # we also cancel bridges prior to prevent more children
          self.class.new(
            pipeline: child_pipeline.reset,
            current_user: nil,
            cascade_to_children: false,
            execute_async: execute_async?,
            auto_canceled_by_pipeline_id: @auto_canceled_by_pipeline_id
          ).force_execute
        end
      end
    end
  end
end
