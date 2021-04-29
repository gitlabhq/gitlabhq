# frozen_string_literal: true

module Deployments
  class HooksWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :deployment
    feature_category :continuous_delivery

    def perform(params = {})
      params = params.with_indifferent_access

      if (deploy = Deployment.find_by_id(params[:deployment_id]))
        deploy.execute_hooks(params[:status_changed_at].to_time)
      end
    end
  end
end
