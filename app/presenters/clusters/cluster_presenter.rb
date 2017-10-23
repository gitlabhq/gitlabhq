module Clusters
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    presents :cluster

    def gke_cluster_url
      "https://console.cloud.google.com/kubernetes/clusters/details/#{provider.zone}/#{name}" if gcp?
    end
  end
end
