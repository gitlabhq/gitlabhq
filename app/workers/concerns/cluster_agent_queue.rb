# frozen_string_literal: true

module ClusterAgentQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :cluster_agent
    feature_category :deployment_management
  end
end
