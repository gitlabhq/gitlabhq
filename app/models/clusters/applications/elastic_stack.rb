# frozen_string_literal: true

module Clusters
  module Applications
    class ElasticStack < ApplicationRecord
      VERSION = '1.8.0'

      self.table_name = 'clusters_applications_elastic_stacks'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      def set_initial_status
        return unless not_installable?
        return unless cluster&.application_ingress_available?

        ingress = cluster.application_ingress
        self.status = status_states[:installable] if ingress.external_ip_or_hostname?
      end

      def chart
        'stable/elastic-stack'
      end

      def values
        content_values.to_yaml
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: 'elastic-stack',
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files
        )
      end

      def uninstall_command
        Gitlab::Kubernetes::Helm::DeleteCommand.new(
          name: 'elastic-stack',
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          postdelete: post_delete_script
        )
      end

      private

      def specification
        {
          "kibana" => {
            "ingress" => {
              "hosts" => [kibana_hostname],
              "tls" => [{
                "hosts" => [kibana_hostname],
                "secretName" => "kibana-cert"
              }]
            }
          }
        }
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end

      def post_delete_script
        [
          Gitlab::Kubernetes::KubectlCmd.delete("pvc", "--selector", "release=elastic-stack")
        ].compact
      end
    end
  end
end
