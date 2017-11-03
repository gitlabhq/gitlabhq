module Clusters
  class BaseHelmService
    attr_accessor :app

    def initialize(app)
      @app = app
    end

    protected

    def cluster
      app.cluster
    end

    def kubeclient
      cluster.kubeclient
    end

    def helm_api
      @helm_api ||= Gitlab::Kubernetes::Helm.new(kubeclient)
    end
  end
end
