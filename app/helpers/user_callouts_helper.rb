module UserCalloutsHelper
  GKE_CLUSTER_INTEGRATION = 'gke_cluster_integration'.freeze

  def show_gke_cluster_integration_callout?(project)
    can?(current_user, :create_cluster, project) &&
      !user_dismissed?(GKE_CLUSTER_INTEGRATION)
  end

  private

  def user_dismissed?(feature_name)
    current_user&.callouts&.find_by(feature_name: UserCallout.feature_names[feature_name])
  end
end
