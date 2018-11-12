# frozen_string_literal: true

module Clusters
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    presents :cluster

    def gke_cluster_url
      "https://console.cloud.google.com/kubernetes/clusters/details/#{provider.zone}/#{name}" if gcp?
    end

    def can_toggle_cluster?
      can?(current_user, :update_cluster, cluster) && created?
    end

    def show_path
      if cluster.project_type?
        project_cluster_path(project, cluster)
      elsif cluster.group_type?
        group_cluster_path(group, cluster)
      else
        raise NotImplementedError
      end
    end
  end
end
