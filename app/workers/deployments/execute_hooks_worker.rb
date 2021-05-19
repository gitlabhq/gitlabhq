# frozen_string_literal: true

module Deployments
  # TODO: remove in https://gitlab.com/gitlab-org/gitlab/-/issues/329360
  class ExecuteHooksWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :deployment
    feature_category :continuous_delivery
    worker_resource_boundary :cpu

    def perform(deployment_id)
      if (deploy = Deployment.find_by_id(deployment_id))
        deploy.execute_hooks(Time.current)
      end
    end
  end
end
