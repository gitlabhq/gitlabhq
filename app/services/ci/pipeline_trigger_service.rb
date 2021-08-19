# frozen_string_literal: true

module Ci
  class PipelineTriggerService < BaseService
    include Gitlab::Utils::StrongMemoize
    include Services::ReturnServiceResponses

    def execute
      if trigger_from_token
        set_application_context_from_trigger(trigger_from_token)
        create_pipeline_from_trigger(trigger_from_token)
      elsif job_from_token
        set_application_context_from_job(job_from_token)
        create_pipeline_from_job(job_from_token)
      end

    rescue Ci::AuthJobFinder::AuthError => e
      error(e.message, 401)
    end

    private

    PAYLOAD_VARIABLE_KEY = 'TRIGGER_PAYLOAD'
    PAYLOAD_VARIABLE_HIDDEN_PARAMS = %i[token].freeze

    def create_pipeline_from_trigger(trigger)
      # this check is to not leak the presence of the project if user cannot read it
      return unless trigger.project == project

      response = Ci::CreatePipelineService
        .new(project, trigger.owner, ref: params[:ref], variables_attributes: variables)
        .execute(:trigger, ignore_skip_ci: true) do |pipeline|
          pipeline.trigger_requests.build(trigger: trigger)
        end

      pipeline_service_response(response.payload)
    end

    def pipeline_service_response(pipeline)
      if pipeline.created_successfully?
        success(pipeline: pipeline)
      elsif pipeline.persisted?
        err = pipeline.errors.messages.presence || pipeline.failure_reason.presence || 'Could not create pipeline'
        error(err, :unprocessable_entity)
      else
        error(pipeline.errors.messages, :bad_request)
      end
    end

    def trigger_from_token
      strong_memoize(:trigger) do
        Ci::Trigger.find_by_token(params[:token].to_s)
      end
    end

    def create_pipeline_from_job(job)
      # this check is to not leak the presence of the project if user cannot read it
      return unless can?(job.user, :read_project, project)

      response = Ci::CreatePipelineService
        .new(project, job.user, ref: params[:ref], variables_attributes: variables)
        .execute(:pipeline, ignore_skip_ci: true) do |pipeline|
          source = job.sourced_pipelines.build(
            source_pipeline: job.pipeline,
            source_project: job.project,
            pipeline: pipeline,
            project: project)

          pipeline.source_pipeline = source
        end

      pipeline_service_response(response.payload)
    end

    def job_from_token
      strong_memoize(:job) do
        Ci::AuthJobFinder.new(token: params[:token].to_s).execute!
      end
    end

    def variables
      param_variables + [payload_variable]
    end

    def param_variables
      params[:variables].to_h.map do |key, value|
        { key: key, value: value }
      end
    end

    def payload_variable
      { key: PAYLOAD_VARIABLE_KEY,
        value: params.except(*PAYLOAD_VARIABLE_HIDDEN_PARAMS).to_json,
        variable_type: :file }
    end

    def set_application_context_from_trigger(trigger)
      Gitlab::ApplicationContext.push(
        user: trigger.owner,
        project: trigger.project
      )
    end

    def set_application_context_from_job(job)
      Gitlab::ApplicationContext.push(
        user: job.user,
        project: job.project,
        runner: job.runner
      )
    end
  end
end
