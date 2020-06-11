# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationData
      def uninstall_command
        Gitlab::Kubernetes::Helm::DeleteCommand.new(
          name: name,
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          local_tiller_enabled: cluster.local_tiller_enabled?
        )
      end

      def repository
        nil
      end

      def values
        File.read(chart_values_file)
      end

      def files
        @files ||= begin
          files = { 'values.yaml': values }

          files.merge!(certificate_files) if use_tiller_ssl?

          files
        end
      end

      private

      def use_tiller_ssl?
        return false if cluster.local_tiller_enabled?

        cluster.application_helm.has_ssl?
      end

      def certificate_files
        {
          'ca.pem': ca_cert,
          'cert.pem': helm_cert.cert_string,
          'key.pem': helm_cert.key_string
        }
      end

      def ca_cert
        cluster.application_helm.ca_cert
      end

      def helm_cert
        @helm_cert ||= cluster.application_helm.issue_client_cert
      end

      def chart_values_file
        "#{Rails.root}/vendor/#{name}/values.yaml"
      end
    end
  end
end
