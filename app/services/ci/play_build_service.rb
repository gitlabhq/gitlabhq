# frozen_string_literal: true

module Ci
  class PlayBuildService
    def initialize(current_user:, build:, variables: nil)
      @current_user = current_user
      @build = build
      @variables = variables
      @project = build.project
    end

    def execute
      check_access!

      job = Ci::EnqueueJobService.new(build, current_user: current_user, variables: variables || []).execute

      ServiceResponse.success(payload: { job: job })
    rescue StateMachines::InvalidTransition
      job = retry_build(build.reset)

      ServiceResponse.success(payload: { job: job })
    end

    private

    attr_reader :current_user, :build, :variables, :project

    def retry_build(build)
      Ci::RetryJobService.new(project, current_user).execute(build)[:job]
    end

    def check_access!
      raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(current_user, :play_job, build)

      if variables.present? && !Ability.allowed?(current_user, :set_pipeline_variables, project) # rubocop: disable Style/GuardClause -- readability
        raise Gitlab::Access::AccessDeniedError
      end
    end
  end
end

Ci::PlayBuildService.prepend_mod_with('Ci::PlayBuildService')
