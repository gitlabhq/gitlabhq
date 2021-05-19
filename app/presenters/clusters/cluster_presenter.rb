# frozen_string_literal: true

module Clusters
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    include ::Gitlab::Utils::StrongMemoize
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::UrlHelper
    include IconsHelper

    presents :cluster

    # We do not want to show the group path for clusters belonging to the
    # clusterable, only for the ancestor clusters.
    def item_link(clusterable_presenter, *html_options)
      if cluster.group_type? && clusterable != clusterable_presenter.subject
        contracted_group_name(cluster.group) + ' / ' + link_to_cluster
      else
        link_to_cluster(*html_options)
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

    def show_path(params: {})
      if cluster.project_type?
        project_cluster_path(project, cluster, params)
      elsif cluster.group_type?
        group_cluster_path(group, cluster, params)
      elsif cluster.instance_type?
        admin_cluster_path(cluster, params)
      else
        raise NotImplementedError
      end
    end

    def integrations_path
      if cluster.project_type?
        create_or_update_project_cluster_integration_path(project, cluster)
      elsif cluster.group_type?
        create_or_update_group_cluster_integration_path(group, cluster)
      elsif cluster.instance_type?
        create_or_update_admin_cluster_integration_path(cluster)
      else
        raise NotImplementedError
      end
    end

    def gitlab_managed_apps_logs_path
      return unless logs_project && can_read_cluster?

      if cluster.elastic_stack_adapter&.available?
        elasticsearch_project_logs_path(logs_project, cluster_id: cluster.id, format: :json)
      else
        k8s_project_logs_path(logs_project, cluster_id: cluster.id, format: :json)
      end
    end

    def read_only_kubernetes_platform_fields?
      !cluster.provided_by_user?
    end

    def health_data(clusterable)
      {
        'clusters-path': clusterable.index_path,
        'dashboard-endpoint': clusterable.metrics_dashboard_path(cluster),
        'documentation-path': help_page_path('user/project/clusters/index', anchor: 'monitoring-your-kubernetes-cluster'),
        'add-dashboard-documentation-path': help_page_path('operations/metrics/dashboards/index.md', anchor: 'add-a-new-dashboard-to-your-project'),
        'empty-getting-started-svg-path': image_path('illustrations/monitoring/getting_started.svg'),
        'empty-loading-svg-path': image_path('illustrations/monitoring/loading.svg'),
        'empty-no-data-svg-path': image_path('illustrations/monitoring/no_data.svg'),
        'empty-no-data-small-svg-path': image_path('illustrations/chart-empty-state-small.svg'),
        'empty-unable-to-connect-svg-path': image_path('illustrations/monitoring/unable_to_connect.svg'),
        'settings-path': '',
        'project-path': '',
        'tags-path': ''
      }
    end

    private

    def image_path(path)
      ActionController::Base.helpers.image_path(path)
    end

    # currently log explorer is only available in the scope of the project
    # for group and instance level cluster selected project does not affects
    # fetching logs from gitlab managed apps namespace, therefore any project
    # available to user will be sufficient.
    def logs_project
      strong_memoize(:logs_project) do
        cluster.all_projects.first
      end
    end

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

    def link_to_cluster(html_options: {})
      link_to_if(can_read_cluster?, cluster.name, show_path, html_options)
    end
  end
end

Clusters::ClusterPresenter.prepend_mod_with('Clusters::ClusterPresenter')
