module CalloutsHelper
  def show_gke_cluster_integration_callout?(kube_feature_name, project)
    current_user && !user_dismissed?(kube_feature_name) && project.team.master?(current_user)
  end

  private

  def user_dismissed?(feature_name)
    Callout.find_by(user: current_user, feature_name: feature_name).dismissed_state?
  end
end
