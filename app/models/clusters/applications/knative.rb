# frozen_string_literal: true

module Clusters
  module Applications
    class Knative < ActiveRecord::Base
      VERSION = '0.1.3'.freeze
      REPOSITORY = 'https://storage.googleapis.com/triggermesh-charts'.freeze

      # This is required for helm version <= 2.10.x in order to support
      # Setting up CRDs
      ISTIO_CRDS = 'http://cabnetworks.net/triggermesh-charts/istio-crds.yaml'.freeze

      self.table_name = 'clusters_applications_knative'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION
      default_value_for :domainname, ''

      def chart
        'knative/knative'
      end

      def install_command
        args = []
        if !domainname.nil? && !domainname.eql?('')
          args = ["domain=" + domainname]
        end

        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          repository: REPOSITORY,
          setargs: args
        )
      end

      def client
        cluster&.platform_kubernetes&.kubeclient&.core_client
      end
    end
  end
end
