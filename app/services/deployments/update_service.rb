# frozen_string_literal: true

module Deployments
  class UpdateService
    attr_reader :deployment, :params

    def initialize(deployment, params)
      @deployment = deployment
      @params = params
    end

    def execute
      # A regular update() does not trigger the state machine transitions, which
      # we need to ensure merge requests are linked when changing the status to
      # success. To work around this we use this case statment, using the right
      # event methods to trigger the transition hooks.
      case params[:status]
      when 'running'
        deployment.run
      when 'success'
        deployment.succeed
      when 'failed'
        deployment.drop
      when 'canceled'
        deployment.cancel
      else
        false
      end
    end
  end
end
