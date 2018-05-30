require 'securerandom'

module QA
  module Service
    class KubernetesCluster
      include Service::Shellout

      attr_reader :api_url, :ca_certificate, :token

      def cluster_name
        @cluster_name ||= "qa-cluster-#{SecureRandom.hex(4)}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
      end

      def initialize
      end

      def create!
        shell <<~CMD.tr("\n", ' ')
          gcloud container clusters
          create #{cluster_name}
          --enable-legacy-authorization
          && gcloud container clusters
          get-credentials #{cluster_name}
        CMD

        @api_url = `kubectl config view --minify -o jsonpath='{.clusters[].cluster.server}'`
        @ca_certificate = Base64.decode64(`kubectl get secrets -o jsonpath="{.items[0].data['ca\\.crt']}"`)
        @token = Base64.decode64(`kubectl get secrets -o jsonpath='{.items[0].data.token}'`)
        self
      end

      def remove!
        shell("gcloud container clusters delete #{cluster_name} --quiet --async")
      end
    end
  end
end
