module ClustersHelper
  def enable_add_cluster_button?(project)
    return true if project.clusters.empty?

    project.feature_available?(:multiple_clusters)
  end
end
