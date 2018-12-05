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
      group_path_shortened(cluster.group)
    end
  end

  def group_path_shortened(group)
    components = group.full_path_components

    breadcrumb = if components.size > 2
                   [components.first, '&hellip;'.html_safe, components.last]
                 else
                   components
                 end

    breadcrumb.each_with_object(''.html_safe) do |component, string|
      string.concat(component + ' / ')
    end
  end

  def render_gcp_signup_offer
    return if Gitlab::CurrentSettings.current_application_settings.hide_third_party_offers?
    return unless show_gcp_signup_offer?

    content_tag :section, class: 'no-animate expanded' do
      render 'clusters/clusters/gcp_signup_offer_banner'
    end
  end
end
