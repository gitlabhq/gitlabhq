module ClustersHelper
  def has_multiple_clusters?(project)
    project.feature_available?(:multiple_clusters)
  end

  def render_gcp_signup_offer
    return if Gitlab::CurrentSettings.current_application_settings.hide_third_party_offers?
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'projects/clusters/gcp_signup_offer_banner'
    end
  end

  def rbac_clusters_feature_enabled?
    Feature.enabled?(:rbac_clusters)
  end
end
