# frozen_string_literal: true

module Clusters
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::UrlHelper
    include IconsHelper

    presents :cluster

    # We do not want to show the group path for clusters belonging to the
    # clusterable, only for the ancestor clusters.
    def item_link(clusterable_presenter)
      if cluster.group_type? && clusterable != clusterable_presenter.subject
        contracted_group_name(cluster.group) + ' / ' + link_to_cluster
      else
        link_to_cluster
      end
    end

    def provider_label
      if aws?
        s_('ClusterIntegration|Elastic Kubernetes Service')
      elsif gcp?
        s_('ClusterIntegration|Google Kubernetes Engine')
      end
    end

    def provider_management_url
      if aws?
        "https://console.aws.amazon.com/eks/home?region=#{provider.region}\#/clusters/#{name}"
      elsif gcp?
        "https://console.cloud.google.com/kubernetes/clusters/details/#{provider.zone}/#{name}"
      end
    end

    def can_read_cluster?
      can?(current_user, :read_cluster, cluster)
    end

    def cluster_type_description
      if cluster.project_type?
        s_("ClusterIntegration|Project cluster")
      elsif cluster.group_type?
        s_("ClusterIntegration|Group cluster")
      elsif cluster.instance_type?
        s_("ClusterIntegration|Instance cluster")
      end
    end

    def show_path
      if cluster.project_type?
        project_cluster_path(project, cluster)
      elsif cluster.group_type?
        group_cluster_path(group, cluster)
      elsif cluster.instance_type?
        admin_cluster_path(cluster)
      else
        raise NotImplementedError
      end
    end

    def read_only_kubernetes_platform_fields?
      !cluster.provided_by_user?
    end

    private

    def clusterable
      if cluster.group_type?
        cluster.group
      elsif cluster.project_type?
        cluster.project
      end
    end

    def contracted_group_name(group)
      sanitize(group.full_name)
        .sub(%r{\/.*\/}, "/ #{contracted_icon} /")
        .html_safe
    end

    def contracted_icon
      sprite_icon('ellipsis_h', size: 12, css_class: 'vertical-align-middle')
    end

    def link_to_cluster
      link_to_if(can_read_cluster?, cluster.name, show_path)
    end
  end
end
