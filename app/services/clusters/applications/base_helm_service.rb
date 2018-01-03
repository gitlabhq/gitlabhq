module Clusters
  module Applications
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
        @helm_api ||= Gitlab::Kubernetes::Helm::Api.new(kubeclient)
      end

      def install_command
        @install_command ||= app.install_command
      end
    end
  end
end
