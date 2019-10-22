# frozen_string_literal: true

module Deployments
  class CreateService
    attr_reader :environment, :current_user, :params

    def initialize(environment, current_user, params)
      @environment = environment
      @current_user = current_user
      @params = params
    end

    def execute
      create_deployment.tap do |deployment|
        AfterCreateService.new(deployment).execute if deployment.persisted?
      end
    end

    def create_deployment
      environment.deployments.create(deployment_attributes)
    end

    def deployment_attributes
      # We use explicit parameters here so we never by accident allow parameters
      # to be set that one should not be able to set (e.g. the row ID).
      {
        cluster_id: environment.deployment_platform&.cluster_id,
        project_id: environment.project_id,
        environment_id: environment.id,
        ref: params[:ref],
        tag: params[:tag],
        sha: params[:sha],
        user: current_user,
        on_stop: params[:on_stop],
        status: params[:status]
      }
    end
  end
end
