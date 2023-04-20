# frozen_string_literal: true

module Deployments
  class DropOlderDeploymentsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :deployment
    feature_category :continuous_delivery

    def perform(deployment_id); end
  end
end
