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
    rescue Kubeclient::HttpError => e
      # If the kubernetes auth engine is enabled, it will return 403
      if e.error_code == 403
        Gitlab::ErrorTracking.track_exception(e)
        nil
      else
        raise
      end
    end
  end
end
