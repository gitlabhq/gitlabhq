# frozen_string_literal: true

module Ci
  class RetryJobService < ::BaseService
    include Gitlab::Utils::StrongMemoize
    include Gitlab::InternalEventsTracking
    include Ci::JobRateLimitable

    # @rate_limit - false for internal callers (auto-retry, auto-rollback, the play
    #   fallback) so system-started retries are never throttled or double-counted
    def initialize(project, user = nil, params = {})
      super
      @rate_limit = params.fetch(:rate_limit, true)
    end

    def execute(job, variables: [], inputs: {})
      throttled_response = rate_limited_response(job)
      return throttled_response if throttled_response

      if job.retryable?
        processed_inputs = process_job_inputs(job, inputs)
        return processed_inputs if processed_inputs.error?

        new_job = retry_job(job, variables: variables, inputs: processed_inputs.payload[:inputs])

        track_retry_with_new_input_values(processed_inputs.payload[:inputs])

        ServiceResponse.success(payload: { job: new_job })
      else
        ServiceResponse.error(
          message: 'Job is not retryable',
          payload: { job: job, reason: :not_retryable }
        )
      end
    end

    def clone!(job, variables: [], inputs: {}, enqueue_if_actionable: false, start_pipeline: false)
      # Cloning a job requires a strict type check to ensure
      # the attributes being used for the clone are taken straight
      # from the model and not overridden by other abstractions.
      raise TypeError unless job.instance_of?(Ci::Build) || job.instance_of?(Ci::Bridge)

      pipeline = job.pipeline

      check_access!(job, variables: variables)
      variables = ensure_project_id!(variables)

      new_job = Ci::CloneJobService.new(job, current_user: current_user).execute(
        new_job_variables: variables,
        new_job_inputs: inputs
      )

      # Hold on to the record the clone service shared with `new_job`: the
      # `new_job.reset` in `start_pipeline` drops that association cache.
      job_definition = new_job.association(:job_definition).target

      if enqueue_if_actionable && new_job.action?
        new_job.set_enqueue_immediately!
      end

      start_pipeline_proc = -> { start_pipeline(pipeline, new_job, job_definition) } if start_pipeline

      new_job.run_after_commit do
        new_job.link_to_environment(job.persisted_environment) if job.persisted_environment.present?

        start_pipeline_proc&.call

        ::Ci::CopyCrossDatabaseAssociationsService.new.execute(job, new_job)

        ::MergeRequests::AddTodoWhenBuildFailsService
          .new(project: project)
          .close(new_job)
      end

      add_job = -> do
        ::Ci::Pipelines::AddJobService.new(pipeline).execute!(new_job) do |processable|
          BulkInsertableAssociations.with_bulk_insert do
            processable.save!
          end
        end
      end

      add_job.call

      job.reset # refresh the data to get new values of `retried` and `processed`.
      job.pipeline = pipeline
      job.project = project

      new_job
    end

    private

    def rate_limit?
      @rate_limit
    end

    def rate_limited_response(job)
      return unless Feature.enabled?(:rate_limit_job_retry, project)

      job_rate_limited_response(
        job, key: :job_retry, per_project_key: :job_retry_per_project, message: 'Job retry rate limit exceeded'
      )
    end

    def ensure_project_id!(variables)
      variables.map do |variables|
        variables.merge(project_id: project.id)
      end
    end

    def check_assignable_runners!(job); end

    def retry_job(job, variables: [], inputs: {})
      clone!(job, variables: variables, inputs: inputs, enqueue_if_actionable: true,
        start_pipeline: true).tap do |new_job|
        check_assignable_runners!(new_job) if new_job.is_a?(Ci::Build)

        next if new_job.failed?

        ResetSkippedJobsService.new(project, current_user).execute(job)
      end
    end

    def process_job_inputs(job, inputs)
      Ci::Inputs::ProcessorService.new(job, inputs).execute
    end

    def check_access!(job, variables: [])
      unless can?(current_user, :retry_job, job)
        raise Gitlab::Access::AccessDeniedError, '403 Forbidden'
      end

      if variables.present? && !can?(current_user, :set_pipeline_variables, project)
        raise Gitlab::Access::AccessDeniedError, '403 Forbidden'
      end
    end

    def start_pipeline(pipeline, new_job, job_definition)
      Ci::PipelineCreation::StartPipelineService.new(pipeline).execute
      new_job.reset
      new_job.pipeline = pipeline
      new_job.project = project
      # The definition row is immutable and shared with the source job, so it
      # can be re-attached after the reset dropped the association cache.
      new_job.association(:job_definition).target = job_definition if job_definition
    end

    def track_retry_with_new_input_values(filtered_inputs)
      return unless filtered_inputs.present?

      track_internal_event(
        'retry_job_with_new_input_values',
        project: project,
        user: current_user
      )
    end
  end
end

Ci::RetryJobService.prepend_mod_with('Ci::RetryJobService')
