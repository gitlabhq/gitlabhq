# frozen_string_literal: true

module ClustersHelper
  # EE overrides this
  def has_multiple_clusters?
    false
  end

  # We do not want to show the group path for clusters belonging to the
  # clusterable, only for the ancestor clusters.
  def cluster_group_path_display(cluster, clusterable)
    if cluster.group_type? && cluster.group.id != clusterable.id
      components = cluster.group.full_path_components

      group_path_shortened(components) + ' / ' + link_to_cluster(cluster)
    else
      link_to_cluster(cluster)
    end
  end

  def render_gcp_signup_offer
    return if Gitlab::CurrentSettings.current_application_settings.hide_third_party_offers?
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'clusters/clusters/gcp_signup_offer_banner'
    end
  end

  def render_cluster_help_content?(clusters, clusterable)
    clusters.length > clusterable.clusters.length
  end

  private

  def components_split_by_horizontal_ellipsis(components)
    [
      components.first,
      sprite_icon('ellipsis_h', size: 12, css_class: 'vertical-align-middle').html_safe,
      components.last
    ]
  end

  def link_to_cluster(cluster)
    link_to cluster.name, cluster.show_path
  end

  def group_path_shortened(components)
    breadcrumb = if components.size > 2
                   components_split_by_horizontal_ellipsis(components)
                 else
                   components
                 end

    breadcrumb.join(' / ').html_safe
  end
end
