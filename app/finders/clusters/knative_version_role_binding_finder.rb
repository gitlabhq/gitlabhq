# frozen_string_literal: true

module Clusters
  class KnativeVersionRoleBindingFinder
    attr_reader :cluster

    def initialize(cluster)
      @cluster = cluster
    end

    def execute
      cluster.kubeclient&.get_cluster_role_binding(Clusters::Kubernetes::GITLAB_KNATIVE_VERSION_ROLE_BINDING_NAME)
    rescue Kubeclient::ResourceNotFoundError
      nil
    end
  end
end
