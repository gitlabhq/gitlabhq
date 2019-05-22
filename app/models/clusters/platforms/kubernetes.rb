# frozen_string_literal: true

module Clusters
  module Platforms
    class Kubernetes < ApplicationRecord
      include Gitlab::Kubernetes
      include EnumWithNil
      include AfterCommitQueue

      RESERVED_NAMESPACES = %w(gitlab-managed-apps).freeze

      self.table_name = 'cluster_platforms_kubernetes'

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
        allow_blank: true,
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

      # This is just to maintain compatibility with KubernetesService, which
      # will be removed in https://gitlab.com/gitlab-org/gitlab-ce/issues/39217.
      # It can be removed once KubernetesService is gone.
      delegate :kubernetes_namespace_for, to: :cluster, allow_nil: true

      alias_method :active?, :enabled?

      enum_with_nil authorization_type: {
        unknown_authorization: nil,
        rbac: 1,
        abac: 2
      }

      default_value_for :authorization_type, :rbac

      def predefined_variables(project:)
        Gitlab::Ci::Variables::Collection.new.tap do |variables|
          variables.append(key: 'KUBE_URL', value: api_url)

          if ca_pem.present?
            variables
              .append(key: 'KUBE_CA_PEM', value: ca_pem)
              .append(key: 'KUBE_CA_PEM_FILE', value: ca_pem, file: true)
          end

          if !cluster.managed?
            project_namespace = namespace.presence || "#{project.path}-#{project.id}".downcase

            variables
              .append(key: 'KUBE_URL', value: api_url)
              .append(key: 'KUBE_TOKEN', value: token, public: false, masked: true)
              .append(key: 'KUBE_NAMESPACE', value: project_namespace)
              .append(key: 'KUBECONFIG', value: kubeconfig(project_namespace), public: false, file: true)

          elsif kubernetes_namespace = cluster.kubernetes_namespaces.has_service_account_token.find_by(project: project)
            variables.concat(kubernetes_namespace.predefined_variables)
          end

          variables.concat(cluster.predefined_variables)
        end
      end

      def calculate_reactive_cache_for(environment)
        return unless enabled?

        { pods: read_pods(environment.deployment_namespace) }
      end

      def terminals(environment, data)
        pods = filter_by_project_environment(data[:pods], environment.project.full_path_slug, environment.slug)
        terminals = pods.flat_map { |pod| terminals_for_pod(api_url, environment.deployment_namespace, pod) }.compact
        terminals.each { |terminal| add_terminal_auth(terminal, terminal_auth) }
      end

      def kubeclient
        @kubeclient ||= build_kube_client!
      end

      private

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
          opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
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

        if api_url_changed? || token_changed? || ca_pem_changed?
          errors.add(:base, _('Cannot modify managed Kubernetes cluster'))
          return false
        end

        true
      end
    end
  end
end
