# frozen_string_literal: true

module ClustersHelper
  # EE overrides this
  def has_multiple_clusters?
    false
  end

  def render_gcp_signup_offer
    return if Gitlab::CurrentSettings.current_application_settings.hide_third_party_offers?
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'clusters/clusters/gcp_signup_offer_banner'
    end
  end

  def has_rbac_enabled?(cluster)
    return cluster.platform_kubernetes_rbac? if cluster.platform_kubernetes

    !cluster.provider.legacy_abac?
  end
end
