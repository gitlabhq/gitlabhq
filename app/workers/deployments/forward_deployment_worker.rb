# frozen_string_literal: true

# This worker is deprecated and will be removed in 14.0
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/266381
module Deployments
  class ForwardDeploymentWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :deployment
    feature_category :continuous_delivery

    def perform(deployment_id)
      Deployments::OlderDeploymentsDropService.new(deployment_id).execute
    end
  end
end
