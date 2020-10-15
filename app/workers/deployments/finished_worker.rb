# frozen_string_literal: true

# This worker is deprecated and will be removed in 14.0
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/266381
module Deployments
  class FinishedWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :deployment
    feature_category :continuous_delivery
    worker_resource_boundary :cpu

    def perform(deployment_id)
      if (deploy = Deployment.find_by_id(deployment_id))
        LinkMergeRequestsService.new(deploy).execute
        deploy.execute_hooks
      end
    end
  end
end
