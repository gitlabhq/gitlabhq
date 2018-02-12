module Clusters
  module Applications
    class Ingress < ActiveRecord::Base
      self.table_name = 'clusters_applications_ingress'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      default_value_for :ingress_type, :nginx
      default_value_for :version, :nginx

      enum ingress_type: {
        nginx: 1
      }

      IP_ADDRESS_FETCH_RETRIES = 3

      def chart
        'stable/nginx-ingress'
      end

      def chart_values_file
        "#{Rails.root}/vendor/#{name}/values.yaml"
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(name, chart: chart, chart_values_file: chart_values_file)
      end

      def post_install
        ClusterWaitForIngressIpAddressWorker.perform_in(
          ClusterWaitForIngressIpAddressWorker::INTERVAL, name, id, IP_ADDRESS_FETCH_RETRIES)
      end
    end
  end
end
