module UserCalloutsHelper
  GKE_CLUSTER_INTEGRATION = 'gke_cluster_integration'.freeze

  # Higher value = higher priority
  PRIORITY = {
    GKE_CLUSTER_INTEGRATION: 0
  }.freeze

  def show_gke_cluster_integration_callout?(project)
    current_user && !user_dismissed?(GKE_CLUSTER_INTEGRATION) &&
      can?(current_user, :create_cluster, project)
  end

  private

  def user_dismissed?(feature_name)
    current_user&.callouts&.find_by(feature_name: feature_name)
  end
end
