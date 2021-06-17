# frozen_string_literal: true

module Clusters
  module Platforms
    class Kubernetes < ApplicationRecord
      include Gitlab::Kubernetes
      include EnumWithNil
      include AfterCommitQueue
      include ReactiveCaching
      include NullifyIfBlank

      RESERVED_NAMESPACES = %w(gitlab-managed-apps).freeze

      self.table_name = 'cluster_platforms_kubernetes'
      self.reactive_cache_work_type = :external_dependency

      belongs_to :cluster, inverse_of: :platform_kubernetes, class_name: 'Clusters::Cluster'

      attr_encrypted :password,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

      attr_encrypted :token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

      before_validation :enforce_namespace_to_lower_case
      before_validation :enforce_ca_whitespace_trimming

      validates :namespace,
        allow_nil: true,
        length: 1..63,
        format: {
          with: Gitlab::Regex.kubernetes_namespace_regex,
          message: Gitlab::Regex.kubernetes_namespace_regex_message
        }

      validates :namespace, exclusion: { in: RESERVED_NAMESPACES }

      validate :no_namespace, unless: :allow_user_defined_namespace?

      # We expect to be `active?` only when enabled and cluster is created (the api_url is assigned)
      validates :api_url, public_url: true, presence: true
      validates :token, presence: true
      validates :ca_cert, certificate: true, allow_blank: true, if: :ca_cert_changed?

      validate :prevent_modification, on: :update

      alias_attribute :ca_pem, :ca_cert

      delegate :enabled?, to: :cluster, allow_nil: true
      delegate :provided_by_user?, to: :cluster, allow_nil: true
      delegate :allow_user_defined_namespace?, to: :cluster, allow_nil: true

      alias_method :active?, :enabled?

      enum_with_nil authorization_type: {
        unknown_authorization: nil,
        rbac: 1,
        abac: 2
      }

      default_value_for :authorization_type, :rbac

      nullify_if_blank :namespace

      def predefined_variables(project:, environment_name:, kubernetes_namespace: nil)
        Gitlab::Ci::Variables::Collection.new.tap do |variables|
          variables.append(key: 'KUBE_URL', value: api_url)

          if ca_pem.present?
            variables
              .append(key: 'KUBE_CA_PEM', value: ca_pem)
              .append(key: 'KUBE_CA_PEM_FILE', value: ca_pem, file: true)
          end

          if !cluster.managed? || cluster.management_project == project
            namespace = kubernetes_namespace || default_namespace(project, environment_name: environment_name)

            variables
              .append(key: 'KUBE_TOKEN', value: token, public: false, masked: true)
              .append(key: 'KUBE_NAMESPACE', value: namespace)
              .append(key: 'KUBECONFIG', value: kubeconfig(namespace), public: false, file: true)

          elsif persisted_namespace = find_persisted_namespace(project, environment_name: environment_name)
            variables.concat(persisted_namespace.predefined_variables)
          end

          variables.concat(cluster.predefined_variables)
        end
      end

      def calculate_reactive_cache_for(environment)
        return unless enabled?

        pods = read_pods(environment.deployment_namespace)
        deployments = read_deployments(environment.deployment_namespace)

        ingresses = read_ingresses(environment.deployment_namespace)

        # extract only the data required for display to avoid unnecessary caching
        {
          pods: extract_relevant_pod_data(pods),
          deployments: extract_relevant_deployment_data(deployments),
          ingresses: extract_relevant_ingress_data(ingresses)
        }
      end

      def terminals(environment, data)
        pods = filter_by_project_environment(data[:pods], environment.project.full_path_slug, environment.slug)
        terminals = pods.flat_map { |pod| terminals_for_pod(api_url, environment.deployment_namespace, pod) }.compact
        terminals.each { |terminal| add_terminal_auth(terminal, **terminal_auth) }
      end

      def kubeclient
        @kubeclient ||= build_kube_client!
      end

      def rollout_status(environment, data)
        project = environment.project

        deployments = filter_by_project_environment(data[:deployments], project.full_path_slug, environment.slug)
        pods = filter_by_project_environment(data[:pods], project.full_path_slug, environment.slug)
        ingresses = data[:ingresses].presence || []

        ::Gitlab::Kubernetes::RolloutStatus.from_deployments(*deployments, pods_attrs: pods, ingresses: ingresses)
      end

      def ingresses(namespace)
        ingresses = read_ingresses(namespace)
        ingresses.map { |ingress| ::Gitlab::Kubernetes::Ingress.new(ingress) }
      end

      def patch_ingress(namespace, ingress, data)
        kubeclient.patch_ingress(ingress.name, data, namespace)
      end

      private

      def default_namespace(project, environment_name:)
        Gitlab::Kubernetes::DefaultNamespace.new(
          cluster,
          project: project
        ).from_environment_name(environment_name)
      end

      def find_persisted_namespace(project, environment_name:)
        Clusters::KubernetesNamespaceFinder.new(
          cluster,
          project: project,
          environment_name: environment_name
        ).execute
      end

      def kubeconfig(namespace)
        to_kubeconfig(
          url: api_url,
          namespace: namespace,
          token: token,
          ca_pem: ca_pem)
      end

      def read_pods(namespace)
        kubeclient.get_pods(namespace: namespace).as_json
      rescue Kubeclient::ResourceNotFoundError
        []
      end

      def read_deployments(namespace)
        kubeclient.get_deployments(namespace: namespace).as_json
      rescue Kubeclient::ResourceNotFoundError
        []
      end

      def read_ingresses(namespace)
        kubeclient.get_ingresses(namespace: namespace).as_json
      rescue Kubeclient::ResourceNotFoundError
        []
      end

      def build_kube_client!
        raise "Incomplete settings" unless api_url

        unless (username && password) || token
          raise "Either username/password or token is required to access API"
        end

        Gitlab::Kubernetes::KubeClient.new(
          api_url,
          auth_options: kubeclient_auth_options,
          ssl_options: kubeclient_ssl_options,
          http_proxy_uri: ENV['http_proxy']
        )
      end

      def kubeclient_ssl_options
        opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

        if ca_pem.present?
          opts[:cert_store] = OpenSSL::X509::Store.new

          file = Tempfile.new('cluster_ca_pem_temp')
          begin
            file.write(ca_pem)
            file.rewind
            opts[:cert_store].add_file(file.path)
          ensure
            file.close
            file.unlink # deletes the temp file
          end
        end

        opts
      end

      def kubeclient_auth_options
        { bearer_token: token }
      end

      def terminal_auth
        {
          token: token,
          ca_pem: ca_pem,
          max_session_time: Gitlab::CurrentSettings.terminal_max_session_time
        }
      end

      def enforce_namespace_to_lower_case
        self.namespace = self.namespace&.downcase
      end

      def enforce_ca_whitespace_trimming
        self.ca_pem = self.ca_pem&.strip
        self.token = self.token&.strip
      end

      def no_namespace
        if namespace
          errors.add(:namespace, 'only allowed for project cluster')
        end
      end

      def prevent_modification
        return if provided_by_user?

        if api_url_changed? || attribute_changed?(:token) || ca_pem_changed?
          errors.add(:base, _('Cannot modify managed Kubernetes cluster'))
          return false
        end

        true
      end

      def extract_relevant_pod_data(pods)
        pods.map do |pod|
          {
            'metadata' => pod.fetch('metadata', {})
                             .slice('name', 'generateName', 'labels', 'annotations', 'creationTimestamp'),
            'status' => pod.fetch('status', {}).slice('phase'),
            'spec' => {
              'containers' => pod.fetch('spec', {})
                                 .fetch('containers', [])
                                 .map { |c| c.slice('name') }
            }
          }
        end
      end

      def extract_relevant_deployment_data(deployments)
        deployments.map do |deployment|
          {
            'metadata' => deployment.fetch('metadata', {}).slice('name', 'generation', 'labels', 'annotations'),
            'spec' => deployment.fetch('spec', {}).slice('replicas'),
            'status' => deployment.fetch('status', {}).slice('observedGeneration')
          }
        end
      end

      def extract_relevant_ingress_data(ingresses)
        ingresses.map do |ingress|
          {
            'metadata' => ingress.fetch('metadata', {}).slice('name', 'labels', 'annotations')
          }
        end
      end
    end
  end
end
