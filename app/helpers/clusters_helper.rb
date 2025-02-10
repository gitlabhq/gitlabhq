# frozen_string_literal: true

module ClustersHelper
  def display_cluster_agents?(clusterable)
    clusterable.is_a?(Project)
  end

  def js_clusters_list_data(clusterable)
    {
      ancestor_help_path: help_page_path('user/group/clusters/_index.md', anchor: 'cluster-precedence'),
      endpoint: clusterable.index_path(format: :json),
      img_tags: {
        aws: { path: image_path('illustrations/logos/amazon_eks.svg'), text: s_('ClusterIntegration|Amazon EKS') },
        default: { path: image_path('illustrations/logos/kubernetes.svg'), text: _('Kubernetes Cluster') },
        gcp: { path: image_path('illustrations/logos/google_gke.svg'), text: s_('ClusterIntegration|Google GKE') }
      },
      clusters_empty_state_image: image_path('illustrations/empty-state/empty-cloud-md.svg'),
      empty_state_image: image_path('illustrations/empty-state/empty-environment-md.svg'),
      empty_state_help_text: clusterable.empty_state_help_text,
      add_cluster_path: clusterable.connect_path,
      new_cluster_docs_path: clusterable.new_cluster_docs_path,
      can_add_cluster: clusterable.can_add_cluster?.to_s,
      can_admin_cluster: clusterable.can_admin_cluster?.to_s,
      display_cluster_agents: display_cluster_agents?(clusterable).to_s,
      certificate_based_clusters_enabled: clusterable.certificate_based_clusters_enabled?.to_s,
      default_branch_name: default_branch_name(clusterable),
      project_path: clusterable_project_path(clusterable),
      kas_address: Gitlab::Kas.external_url,
      kas_install_version: Gitlab::Kas.install_version_info,
      kas_check_version: Gitlab::Kas.display_version_info
    }
  end

  def js_cluster_form_data(cluster, can_edit)
    {
      enabled: cluster.enabled?.to_s,
      editable: can_edit.to_s,
      environment_scope: cluster.environment_scope,
      base_domain: cluster.base_domain,
      auto_devops_help_path: help_page_path('topics/autodevops/_index.md'),
      external_endpoint_help_path: help_page_path('user/project/clusters/gitlab_managed_clusters.md', anchor: 'base-domain')
    }
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
    !cluster.status_name.in?(%i[scheduled creating])
  end

  def can_admin_cluster?(user, cluster)
    can?(user, :admin_cluster, cluster)
  end

  private

  def default_branch_name(clusterable)
    clusterable.default_branch if clusterable.is_a?(Project)
  end

  def clusterable_project_path(clusterable)
    clusterable.full_path if clusterable.is_a?(Project)
  end
end
