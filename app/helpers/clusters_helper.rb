module ClustersHelper
  def can_toggle_cluster?(cluster)
    can?(current_user, :update_cluster, cluster) && cluster.created?
  end
end
