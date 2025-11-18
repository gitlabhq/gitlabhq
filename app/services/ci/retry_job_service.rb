# frozen_string_literal: true

module Ci
  class RetryJobService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(job, variables: [], inputs: {})
      if job.retryable?
        processed_inputs = process_job_inputs(job, inputs)
        return processed_inputs if processed_inputs.error?

        job.ensure_scheduling_type!
        new_job = retry_job(job, variables: variables, inputs: processed_inputs.payload[:inputs])

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

      check_access!(job)
      variables = ensure_project_id!(variables)

      new_job = Ci::CloneJobService.new(job, current_user: current_user).execute(
        new_job_variables: variables,
        new_job_inputs: inputs
      )

      if enqueue_if_actionable && new_job.action?
        new_job.set_enqueue_immediately!
      end

      start_pipeline_proc = -> { start_pipeline(job, new_job) } if start_pipeline

      new_job.run_after_commit do
        new_job.link_to_environment(job.persisted_environment) if job.persisted_environment.present?

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

    def retry_job(job, variables: [], inputs: {})
      clone!(job, variables: variables, inputs: inputs, enqueue_if_actionable: true,
        start_pipeline: true).tap do |new_job|
        check_assignable_runners!(new_job) if new_job.is_a?(Ci::Build)

        next if new_job.failed?

        ResetSkippedJobsService.new(project, current_user).execute(job)
      end
    end

    def process_job_inputs(job, inputs)
      validation_result = validate_inputs(job, inputs)
      return validation_result if validation_result.error?

      filtered_inputs = filter_inputs_with_defaults(job, inputs)
      ServiceResponse.success(payload: { inputs: filtered_inputs })
    end

    def validate_inputs(job, inputs)
      return ServiceResponse.success if inputs.blank?

      inputs_spec = job.options[:inputs]
      return ServiceResponse.success unless inputs_spec.present?

      provided_input_keys = inputs.keys.map(&:to_s)
      spec_keys = inputs_spec.keys.map(&:to_s)
      unknown_inputs = provided_input_keys - spec_keys

      if unknown_inputs.any?
        return ServiceResponse.error(
          message: "Unknown input#{'s' if unknown_inputs.size > 1}: #{unknown_inputs.join(', ')}"
        )
      end

      provided_spec_keys = inputs_spec.keys.select { |key| provided_input_keys.include?(key.to_s) }
      provided_specs = inputs_spec.slice(*provided_spec_keys)
      builder = ::Ci::Inputs::Builder.new(provided_specs)
      builder.validate_input_params!(inputs)

      if builder.errors.any?
        ServiceResponse.error(message: builder.errors.join(', '))
      else
        ServiceResponse.success
      end
    end

    def filter_inputs_with_defaults(job, inputs)
      return {} if inputs.blank?

      inputs_spec = job.options[:inputs]
      return inputs unless inputs_spec.present?

      inputs.reject do |name, value|
        spec = inputs_spec[name]
        next false unless spec&.key?(:default)

        value == spec[:default]
      end
    end

    def check_access!(job)
      unless can?(current_user, :retry_job, job)
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
