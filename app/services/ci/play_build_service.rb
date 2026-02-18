# frozen_string_literal: true

module Ci
  class PlayBuildService
    include Gitlab::InternalEventsTracking

    def initialize(current_user:, build:, variables: nil, inputs: {})
      @current_user = current_user
      @build = build
      @variables = variables
      @inputs = inputs
      @project = build.project
    end

    def execute
      check_access!

      if Feature.enabled?(:ci_job_inputs, project)
        input_process_result = process_job_inputs(build, inputs)

        return ServiceResponse.error(message: input_process_result.message) if input_process_result.error?

        filtered_inputs = input_process_result.payload[:inputs]
      else
        filtered_inputs = {}
      end

      job = Ci::EnqueueJobService.new(
        build,
        current_user: current_user,
        variables: variables || [],
        inputs: filtered_inputs
      ).execute

      track_play_with_new_input_values(filtered_inputs)

      ServiceResponse.success(payload: { job: job })
    rescue StateMachines::InvalidTransition
      job = retry_build(build.reset)

      ServiceResponse.success(payload: { job: job })
    end

    private

    attr_reader :current_user, :build, :variables, :inputs, :project

    def retry_build(build)
      Ci::RetryJobService.new(project, current_user).execute(build)[:job]
    end

    def check_access!
      raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(current_user, :play_job, build)

      if variables.present? && !Ability.allowed?(current_user, :set_pipeline_variables, project) # rubocop: disable Style/GuardClause -- readability
        raise Gitlab::Access::AccessDeniedError
      end
    end

    def process_job_inputs(job, inputs)
      Ci::Inputs::ProcessorService.new(job, inputs).execute
    end

    def track_play_with_new_input_values(filtered_inputs)
      return unless filtered_inputs.present?

      track_internal_event(
        'play_job_with_new_input_values',
        project: project,
        user: current_user
      )
    end
  end
end

Ci::PlayBuildService.prepend_mod_with('Ci::PlayBuildService')
