# frozen_string_literal: true

module Ci
  class RetryJobService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(job, variables: [])
      if job.retryable?
        job.ensure_scheduling_type!
        new_job = retry_job(job, variables: variables)

        ServiceResponse.success(payload: { job: new_job })
      else
        ServiceResponse.error(
          message: 'Job cannot be retried',
          payload: { job: job, reason: :not_retryable }
        )
      end
    end

    def clone!(job, variables: [], enqueue_if_actionable: false, start_pipeline: false)
      # Cloning a job requires a strict type check to ensure
      # the attributes being used for the clone are taken straight
      # from the model and not overridden by other abstractions.
      raise TypeError unless job.instance_of?(Ci::Build) || job.instance_of?(Ci::Bridge)

      check_access!(job)
      variables = ensure_project_id!(variables)

      new_job = job.clone(current_user: current_user, new_job_variables_attributes: variables)
      if enqueue_if_actionable && new_job.action?
        new_job.set_enqueue_immediately!
      end

      start_pipeline_proc = -> { start_pipeline(job, new_job) } if start_pipeline

      new_job.run_after_commit do
        start_pipeline_proc&.call

        ::Ci::CopyCrossDatabaseAssociationsService.new.execute(job, new_job)

        ::MergeRequests::AddTodoWhenBuildFailsService
          .new(project: project)
          .close(new_job)
      end

      add_job = -> do
        ::Ci::Pipelines::AddJobService.new(job.pipeline).execute!(new_job) do |processable|
          BulkInsertableAssociations.with_bulk_insert do
            processable.save!
          end
        end
      end

      add_job.call

      job.reset # refresh the data to get new values of `retried` and `processed`.

      new_job
    end

    private

    def ensure_project_id!(variables)
      variables.map do |variables|
        variables.merge(project_id: project.id)
      end
    end

    def check_assignable_runners!(job); end

    def retry_job(job, variables: [])
      clone!(job, variables: variables, enqueue_if_actionable: true, start_pipeline: true).tap do |new_job|
        check_assignable_runners!(new_job) if new_job.is_a?(Ci::Build)

        next if new_job.failed?

        ResetSkippedJobsService.new(project, current_user).execute(job)
      end
    end

    def check_access!(job)
      unless can?(current_user, :update_build, job)
        raise Gitlab::Access::AccessDeniedError, '403 Forbidden'
      end
    end

    def start_pipeline(job, new_job)
      Ci::PipelineCreation::StartPipelineService.new(job.pipeline).execute
      new_job.reset
    end
  end
end

Ci::RetryJobService.prepend_mod_with('Ci::RetryJobService')
