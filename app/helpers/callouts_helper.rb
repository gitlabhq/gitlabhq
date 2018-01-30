module CalloutsHelper
  GKE_CLUSTER_INTEGRATION = 'gke_cluster_integration'.freeze

  def show_gke_cluster_integration_callout?(project)
    current_user && !user_dismissed?(GKE_CLUSTER_INTEGRATION) &&
      (project.team.master?(current_user) ||
       current_user == project.owner)
  end

  private

  def user_dismissed?(feature_name)
    Callout.find_by(user: current_user, feature_name: feature_name)&.dismissed_state?
  end
end
