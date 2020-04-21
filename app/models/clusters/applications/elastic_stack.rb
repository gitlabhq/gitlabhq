# frozen_string_literal: true

module Clusters
  module Applications
    class ElasticStack < ApplicationRecord
      VERSION = '2.0.0'

      ELASTICSEARCH_PORT = 9200

      self.table_name = 'clusters_applications_elastic_stacks'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include ::Gitlab::Utils::StrongMemoize

      default_value_for :version, VERSION

      def chart
        'stable/elastic-stack'
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: 'elastic-stack',
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          preinstall: migrate_to_2_script,
          postinstall: post_install_script
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

      def files
        super.merge('wait-for-elasticsearch.sh': File.read("#{Rails.root}/vendor/elastic_stack/wait-for-elasticsearch.sh"))
      end

      def elasticsearch_client
        strong_memoize(:elasticsearch_client) do
          next unless kube_client

          proxy_url = kube_client.proxy_url('service', 'elastic-stack-elasticsearch-client', ::Clusters::Applications::ElasticStack::ELASTICSEARCH_PORT, Gitlab::Kubernetes::Helm::NAMESPACE)

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

      def filebeat7?
        Gem::Version.new(version) >= Gem::Version.new('2.0.0')
      end

      private

      def post_install_script
        [
          "timeout -t60 sh /data/helm/elastic-stack/config/wait-for-elasticsearch.sh http://elastic-stack-elasticsearch-client:9200"
        ]
      end

      def post_delete_script
        [
          Gitlab::Kubernetes::KubectlCmd.delete("pvc", "--selector", "release=elastic-stack")
        ]
      end

      def kube_client
        cluster&.kubeclient&.core_client
      end

      def migrate_to_2_script
        # Updating the chart to 2.0.0 includes an update of the filebeat chart from 1.7.0 to 3.1.1 https://github.com/helm/charts/pull/21640
        # This includes the following commit that changes labels on the filebeat deployment https://github.com/helm/charts/commit/9b009170686c6f4b202c36ceb1da4bb9ba15ddd0
        # Unfortunately those fields are immutable, and we can't use `helm upgrade` to change them. We first have to delete the associated filebeat resources
        # The following pre-install command runs before updating to 2.0.0 and sets filebeat.enable=false so the filebeat deployment is deleted.
        # Then the main install command re-creates them properly
        if updating? && !filebeat7?
          [
            Gitlab::Kubernetes::Helm::InstallCommand.new(
              name: 'elastic-stack',
              version: version,
              rbac: cluster.platform_kubernetes_rbac?,
              chart: chart,
              files: files
            ).install_command + ' --set filebeat.enabled\\=false'
          ]
        else
          []
        end
      end
    end
  end
end
