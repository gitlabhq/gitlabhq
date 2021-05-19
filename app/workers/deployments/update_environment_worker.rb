# frozen_string_literal: true

module Deployments
  class UpdateEnvironmentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :deployment
    idempotent!
    feature_category :continuous_delivery
    worker_resource_boundary :cpu

    def perform(deployment_id)
      Deployment.find_by_id(deployment_id).try do |deployment|
        break unless deployment.success?

        Deployments::UpdateEnvironmentService.new(deployment).execute
      end
    end
  end
end
