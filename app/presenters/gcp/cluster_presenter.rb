module Gcp
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    presents :cluster

    def gke_cluster_url
      "https://console.cloud.google.com/kubernetes/clusters/details/#{gcp_cluster_zone}/#{gcp_cluster_name}"
    end
  end
end
