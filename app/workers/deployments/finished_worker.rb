# frozen_string_literal: true

module Deployments
  class FinishedWorker
    include ApplicationWorker

    queue_namespace :deployment

    def perform(deployment_id)
      Deployment.find_by_id(deployment_id).try(:execute_hooks)
    end
  end
end
