# frozen_string_literal: true

# This worker is deprecated and will be removed in 14.0
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/266381
module Deployments
  class SuccessWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :deployment
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
