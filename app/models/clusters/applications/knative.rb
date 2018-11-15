# frozen_string_literal: true

module Clusters
  module Applications
    class Knative < ActiveRecord::Base
      VERSION = '0.1.3'.freeze
      REPOSITORY = 'https://storage.googleapis.com/triggermesh-charts'.freeze

      # This is required for helm version <= 2.10.x in order to support
      # Setting up CRDs
      ISTIO_CRDS = 'https://storage.googleapis.com/triggermesh-charts/istio-crds.yaml'.freeze

      self.table_name = 'clusters_applications_knative'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      validates :hostname, presence: true, hostname: true

      def chart
        'knative/knative'
      end

      def values
        { "domain" => hostname }.to_yaml
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          repository: REPOSITORY,
          preinstall: install_script
        )
      end

      def client
        cluster.platform_kubernetes.kubeclient.knative_client
      end

      private

      def install_script
        ["/usr/bin/kubectl apply -f #{ISTIO_CRDS}"]
      end
    end
  end
end
