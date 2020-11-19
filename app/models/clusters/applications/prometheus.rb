# frozen_string_literal: true

module Clusters
  module Applications
    class Prometheus < ApplicationRecord
      include PrometheusAdapter

      VERSION = '10.4.1'

      self.table_name = 'clusters_applications_prometheus'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      default_value_for :version, VERSION

      scope :preload_cluster_platform, -> { preload(cluster: [:platform_kubernetes]) }
      scope :with_clusters_with_cilium, -> { joins(:cluster).merge(Clusters::Cluster.with_available_cilium) }

      attr_encrypted :alert_manager_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-gcm'

      after_destroy do
        run_after_commit do
          disable_prometheus_integration
        end
      end

      state_machine :status do
        after_transition any => [:installed] do |application|
          application.run_after_commit do
            Clusters::Applications::ActivateServiceWorker
              .perform_async(application.cluster_id, ::PrometheusService.to_param) # rubocop:disable CodeReuse/ServiceClass
          end
        end

        after_transition any => :updating do |application|
          application.update(last_update_started_at: Time.current)
        end
      end

      def updated_since?(timestamp)
        last_update_started_at &&
          last_update_started_at > timestamp &&
          !update_errored?
      end

      def chart
        "#{name}/prometheus"
      end

      def repository
        'https://gitlab-org.gitlab.io/cluster-integration/helm-stable-archive'
      end

      def service_name
        'prometheus-prometheus-server'
      end

      def service_port
        80
      end

      def install_command
        helm_command_module::InstallCommand.new(
          name: name,
          repository: repository,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          postinstall: install_knative_metrics
        )
      end

      def patch_command(values)
        helm_command_module::PatchCommand.new(
          name: name,
          repository: repository,
          version: version,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files_with_replaced_values(values)
        )
      end

      def uninstall_command
        helm_command_module::DeleteCommand.new(
          name: name,
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          predelete: delete_knative_istio_metrics
        )
      end

      # Returns a copy of files where the values of 'values.yaml'
      # are replaced by the argument.
      #
      # See #values for the data format required
      def files_with_replaced_values(replaced_values)
        files.merge('values.yaml': replaced_values)
      end

      def prometheus_client
        return unless kube_client

        proxy_url = kube_client.proxy_url('service', service_name, service_port, Gitlab::Kubernetes::Helm::NAMESPACE)

        # ensures headers containing auth data are appended to original k8s client options
        options = kube_client.rest_client.options
          .merge(prometheus_client_default_options)
          .merge(headers: kube_client.headers)
        Gitlab::PrometheusClient.new(proxy_url, options)
      rescue Kubeclient::HttpError, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ENETUNREACH
        # If users have mistakenly set parameters or removed the depended clusters,
        # `proxy_url` could raise an exception because gitlab can not communicate with the cluster.
        # Since `PrometheusAdapter#can_query?` is eargely loaded on environement pages in gitlab,
        # we need to silence the exceptions
      end

      def configured?
        kube_client.present? && available?
      rescue Gitlab::UrlBlocker::BlockedUrlError
        false
      end

      def generate_alert_manager_token!
        unless alert_manager_token.present?
          update!(alert_manager_token: generate_token)
        end
      end

      private

      def generate_token
        SecureRandom.hex
      end

      def disable_prometheus_integration
        ::Clusters::Applications::DeactivateServiceWorker
          .perform_async(cluster_id, ::PrometheusService.to_param) # rubocop:disable CodeReuse/ServiceClass
      end

      def kube_client
        cluster&.kubeclient&.core_client
      end

      def install_knative_metrics
        return [] unless cluster.application_knative_available?

        [Gitlab::Kubernetes::KubectlCmd.apply_file(Clusters::Applications::Knative::METRICS_CONFIG)]
      end

      def delete_knative_istio_metrics
        return [] unless cluster.application_knative_available?

        [
          Gitlab::Kubernetes::KubectlCmd.delete(
            "-f", Clusters::Applications::Knative::METRICS_CONFIG,
            "--ignore-not-found"
          )
        ]
      end
    end
  end
end
