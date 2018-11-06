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

      validates :hostname, presence: true

      def chart
        'knative/knative'
      end

      def values
        { domain: hostname }.to_yaml
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          repository: REPOSITORY,
          preinstall: install_script,
          postinstall: setup_knative_role
        )
      end

      private

      def install_script
        ["/usr/bin/kubectl apply -f #{ISTIO_CRDS} >/dev/null"]
      end

      def setup_knative_role
        if !cluster.kubernetes_namespace.nil?
          [
            "echo \'#{create_rolebinding.to_yaml}\' > /tmp/rolebinding.yaml\n",
            "/usr/bin/kubectl apply -f /tmp/rolebinding.yaml > /dev/null"
          ]
        else
          nil
        end
      end

      def create_rolebinding
        {
          "apiVersion" => "rbac.authorization.k8s.io/v1",
          "kind" => "ClusterRoleBinding",
          "metadata" => {
            "name" => create_role_binding_name,
            "namespace" => namespace
          },
          "roleRef" => {
            "apiGroup" => "rbac.authorization.k8s.io",
            "kind" => "ClusterRole",
            "name" => "knative-serving-admin"
          },
          "subjects" => role_subject
        }
      end

      def create_role_binding_name
        "#{namespace}-knative-binding"
      end

      def service_account_name
        cluster.kubernetes_namespace.service_account_name
      end

      def role_subject
        [{ "kind" => 'ServiceAccount', "name" => service_account_name, "namespace" => namespace }]
      end

      def namespace
        cluster.kubernetes_namespace.namespace
      end
    end
  end
end
