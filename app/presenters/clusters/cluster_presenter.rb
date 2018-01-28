module Clusters
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    presents :cluster

    def gke_cluster_url
      "https://console.cloud.google.com/kubernetes/clusters/details/#{provider.zone}/#{name}" if gcp?
    end

    def can_toggle_cluster?
      can?(current_user, :update_cluster, cluster) && created?
    end
  end
end
