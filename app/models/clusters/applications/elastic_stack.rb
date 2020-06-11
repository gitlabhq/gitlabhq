# frozen_string_literal: true

module Clusters
  module Applications
    class ElasticStack < ApplicationRecord
      VERSION = '3.0.0'

      ELASTICSEARCH_PORT = 9200

      self.table_name = 'clusters_applications_elastic_stacks'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include ::Gitlab::Utils::StrongMemoize

      default_value_for :version, VERSION

      def chart
        'elastic-stack/elastic-stack'
      end

      def repository
        'https://charts.gitlab.io'
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: 'elastic-stack',
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          repository: repository,
          files: files,
          preinstall: migrate_to_3_script,
          postinstall: post_install_script,
          local_tiller_enabled: cluster.local_tiller_enabled?
        )
      end

      def uninstall_command
        Gitlab::Kubernetes::Helm::DeleteCommand.new(
          name: 'elastic-stack',
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          postdelete: post_delete_script,
          local_tiller_enabled: cluster.local_tiller_enabled?
        )
      end

      def files
        super.merge('wait-for-elasticsearch.sh': File.read("#{Rails.root}/vendor/elastic_stack/wait-for-elasticsearch.sh"))
      end

      def elasticsearch_client
        strong_memoize(:elasticsearch_client) do
          next unless kube_client

          proxy_url = kube_client.proxy_url('service', service_name, ::Clusters::Applications::ElasticStack::ELASTICSEARCH_PORT, Gitlab::Kubernetes::Helm::NAMESPACE)

          Elasticsearch::Client.new(url: proxy_url) do |faraday|
            # ensures headers containing auth data are appended to original client options
            faraday.headers.merge!(kube_client.headers)
            # ensure TLS certs are properly verified
            faraday.ssl[:verify] = kube_client.ssl_options[:verify_ssl]
            faraday.ssl[:cert_store] = kube_client.ssl_options[:cert_store]
          end

        rescue Kubeclient::HttpError => error
          # If users have mistakenly set parameters or removed the depended clusters,
          # `proxy_url` could raise an exception because gitlab can not communicate with the cluster.
          # We check for a nil client in downstream use and behaviour is equivalent to an empty state
          log_exception(error, :failed_to_create_elasticsearch_client)

          nil
        end
      end

      def chart_above_v2?
        Gem::Version.new(version) >= Gem::Version.new('2.0.0')
      end

      def chart_above_v3?
        Gem::Version.new(version) >= Gem::Version.new('3.0.0')
      end

      private

      def service_name
        chart_above_v3? ? 'elastic-stack-elasticsearch-master' : 'elastic-stack-elasticsearch-client'
      end

      def pvc_selector
        chart_above_v3? ? "app=elastic-stack-elasticsearch-master" : "release=elastic-stack"
      end

      def post_install_script
        [
          "timeout -t60 sh /data/helm/elastic-stack/config/wait-for-elasticsearch.sh http://elastic-stack-elasticsearch-master:9200"
        ]
      end

      def post_delete_script
        [
          Gitlab::Kubernetes::KubectlCmd.delete("pvc", "--selector", pvc_selector, "--namespace", Gitlab::Kubernetes::Helm::NAMESPACE)
        ]
      end

      def kube_client
        cluster&.kubeclient&.core_client
      end

      def migrate_to_3_script
        return [] if !updating? || chart_above_v3?

        # Chart version 3.0.0 moves to our own chart at https://gitlab.com/gitlab-org/charts/elastic-stack
        # and is not compatible with pre-existing resources. We first remove them.
        [
          Gitlab::Kubernetes::Helm::DeleteCommand.new(
            name: 'elastic-stack',
            rbac: cluster.platform_kubernetes_rbac?,
            files: files,
            local_tiller_enabled: cluster.local_tiller_enabled?
          ).delete_command,
          Gitlab::Kubernetes::KubectlCmd.delete("pvc", "--selector", "release=elastic-stack", "--namespace", Gitlab::Kubernetes::Helm::NAMESPACE)
        ]
      end
    end
  end
end
