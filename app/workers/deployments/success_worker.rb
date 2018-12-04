# frozen_string_literal: true

module Deployments
  class SuccessWorker
    include ApplicationWorker

    queue_namespace :deployment

    def perform(deployment_id)
      Deployment.find_by_id(deployment_id).try do |deployment|
        break unless deployment.success?

        UpdateDeploymentService.new(deployment).execute
      end
    end
  end
end
