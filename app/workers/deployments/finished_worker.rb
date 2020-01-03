# frozen_string_literal: true

module Deployments
  class FinishedWorker
    include ApplicationWorker

    queue_namespace :deployment
    feature_category :continuous_delivery
    worker_resource_boundary :cpu

    def perform(deployment_id)
      if (deploy = Deployment.find_by_id(deployment_id))
        link_merge_requests(deploy)
        deploy.execute_hooks
      end
    end

    def link_merge_requests(deployment)
      unless Feature.enabled?(:deployment_merge_requests, deployment.project)
        return
      end

      LinkMergeRequestsService.new(deployment).execute
    end
  end
end
