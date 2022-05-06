# frozen_string_literal: true

module Clusters
  class Instance
    def clusters
      Clusters::Cluster.instance_type
    end

    def flipper_id
      self.class.to_s
    end

    def certificate_based_clusters_enabled?
      ::Gitlab::SafeRequestStore.fetch("certificate_based_clusters:") do
        Feature.enabled?(:certificate_based_clusters, type: :ops)
      end
    end
  end
end
