# frozen_string_literal: true

module Deployments
  class SuccessWorker
    include ApplicationWorker

    queue_namespace :deployment

    def perform(deployment_id)
      Deployment.find_by_id(deployment_id).try do |deployment|
        if deployment.deployed?
          StartEnvironmentService.new(deployment).execute
        elsif deployment.stopped?
          StopEnvironmentService.new(deployment).execute
        end
      end
    end
  end
end
