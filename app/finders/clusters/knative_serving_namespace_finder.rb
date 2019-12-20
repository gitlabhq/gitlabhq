# frozen_string_literal: true

module Clusters
  class KnativeServingNamespaceFinder
    attr_reader :cluster

    def initialize(cluster)
      @cluster = cluster
    end

    def execute
      cluster.kubeclient&.get_namespace(Clusters::Kubernetes::KNATIVE_SERVING_NAMESPACE)
    rescue Kubeclient::ResourceNotFoundError
      nil
    end
  end
end
