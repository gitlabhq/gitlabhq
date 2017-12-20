module ClustersHelper
  def has_multiple_clusters?(project)
    project.feature_available?(:multiple_clusters)
  end
end
