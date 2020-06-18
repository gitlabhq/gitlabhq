# frozen_string_literal: true

module ClustersHelper
  # EE overrides this
  def has_multiple_clusters?
    false
  end

  def create_new_cluster_label(provider: nil)
    case provider
    when 'aws'
      s_('ClusterIntegration|Create new cluster on EKS')
    when 'gcp'
      s_('ClusterIntegration|Create new cluster on GKE')
    else
      s_('ClusterIntegration|Create new cluster')
    end
  end

  def js_clusters_list_data(path = nil)
    {
      endpoint: path,
      img_tags: {
        aws: { path: image_path('illustrations/logos/amazon_eks.svg'), text: s_('ClusterIntegration|Amazon EKS') },
        default: { path: image_path('illustrations/logos/kubernetes.svg'), text: _('Kubernetes Cluster') },
        gcp: { path: image_path('illustrations/logos/google_gke.svg'), text: s_('ClusterIntegration|Google GKE') }
      }
    }
  end

  # This method is depreciated and will be removed when associated HAML files are moved to JavaScript
  def provider_icon(provider = nil)
    img_data = js_clusters_list_data.dig(:img_tags, provider&.to_sym) ||
               js_clusters_list_data.dig(:img_tags, :default)

    image_tag img_data[:path], alt: img_data[:text], class: 'gl-h-full'
  end

  def render_gcp_signup_offer
    return if Gitlab::CurrentSettings.current_application_settings.hide_third_party_offers?
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'clusters/clusters/gcp_signup_offer_banner'
    end
  end

  def render_cluster_info_tab_content(tab, expanded)
    case tab
    when 'environments'
      render_if_exists 'clusters/clusters/environments'
    when 'health'
      render_if_exists 'clusters/clusters/health'
    when 'apps'
      render 'applications'
    when 'settings'
      render 'advanced_settings_container'
    else
      render('details', expanded: expanded)
    end
  end

  def cluster_type_label(cluster_type)
    case cluster_type
    when 'project_type'
      s_('ClusterIntegration|Project cluster')
    when 'group_type'
      s_('ClusterIntegration|Group cluster')
    when 'instance_type'
      s_('ClusterIntegration|Instance cluster')
    else
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        ArgumentError.new('Cluster Type Missing'),
        cluster_error: { error: 'Cluster Type Missing', cluster_type: cluster_type }
      )
      _('Cluster')
    end
  end

  def has_rbac_enabled?(cluster)
    return cluster.platform_kubernetes_rbac? if cluster.platform_kubernetes

    cluster.provider.has_rbac_enabled?
  end

  def project_cluster?(cluster)
    cluster.cluster_type.in?('project_type')
  end

  def cluster_created?(cluster)
    !cluster.status_name.in?(%i/scheduled creating/)
  end

  def can_admin_cluster?(user, cluster)
    can?(user, :admin_cluster, cluster)
  end
end

ClustersHelper.prepend_if_ee('EE::ClustersHelper')
