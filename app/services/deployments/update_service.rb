# frozen_string_literal: true

module Deployments
  class UpdateService
    attr_reader :deployment, :params

    def initialize(deployment, params)
      @deployment = deployment
      @params = params
    end

    def execute
      deployment.update_status(params[:status])
    end
  end
end
