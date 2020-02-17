# frozen_string_literal: true

module Deployments
  class ForwardDeploymentWorker
    include ApplicationWorker

    queue_namespace :deployment
    feature_category :continuous_delivery

    def perform(deployment_id)
      Deployments::OlderDeploymentsDropService.new(deployment_id).execute
    end
  end
end
