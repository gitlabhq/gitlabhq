module UserCalloutsHelper
  GKE_CLUSTER_INTEGRATION = 'gke_cluster_integration'.freeze
  GCP_SIGNUP_OFFER = 'gcp_signup_offer'.freeze
  CLUSTER_SECURITY_WARNING = 'cluster_security_warning'.freeze

  def show_gke_cluster_integration_callout?(project)
    can?(current_user, :create_cluster, project) &&
      !user_dismissed?(GKE_CLUSTER_INTEGRATION)
  end

  def show_gcp_signup_offer?
    !user_dismissed?(GCP_SIGNUP_OFFER)
  end

  def show_cluster_security_warning?
    !user_dismissed?(CLUSTER_SECURITY_WARNING)
  end

  private

  def user_dismissed?(feature_name)
    current_user&.callouts&.find_by(feature_name: UserCallout.feature_names[feature_name])
  end
end
