# frozen_string_literal: true

module Deployments
  class DropOlderDeploymentsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :deployment
    feature_category :continuous_delivery
    tags :exclude_from_kubernetes

    def perform(deployment_id)
      Deployments::OlderDeploymentsDropService.new(deployment_id).execute
    end
  end
end
