# frozen_string_literal: true

class Clusters::Instance
  def clusters
    Clusters::Cluster.instance_type
  end

  def feature_available?(feature)
    ::Feature.enabled?(feature, default_enabled: true)
  end

  def instance_clusters_enabled?
    ::Feature.enabled?(:instance_clusters, default_enabled: true)
  end
end
