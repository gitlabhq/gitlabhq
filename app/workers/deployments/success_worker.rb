# frozen_string_literal: true

module Deployments
  class SuccessWorker
    include ApplicationWorker

    queue_namespace :deployment
    feature_category :continuous_delivery

    def perform(deployment_id)
      Deployment.find_by_id(deployment_id).try do |deployment|
        break unless deployment.success?

        Deployments::AfterCreateService.new(deployment).execute
      end
    end
  end
end
