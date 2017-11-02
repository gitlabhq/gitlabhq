module Clusters
  class ClusterPresenter < Gitlab::View::Presenter::Delegated
    presents :cluster

    def gke_cluster_url
      "https://console.cloud.google.com/kubernetes/clusters/details/#{provider.zone}/#{name}" if gcp?
    end

    def applications
      Clusters::Cluster::APPLICATIONS.map do |key, value|
        value.find_by(cluster_id: id)
      end.compact
    end
  end
end
