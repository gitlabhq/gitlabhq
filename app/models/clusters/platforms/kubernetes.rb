module Clusters
  module Platforms
    class Kubernetes < ActiveRecord::Base
      include Gitlab::CurrentSettings
      include Gitlab::Kubernetes
      include ReactiveCaching

      self.table_name = 'cluster_platforms_kubernetes'
      self.reactive_cache_key = ->(kubernetes) { [kubernetes.class.model_name.singular, kubernetes.cluster_id] }

      belongs_to :cluster, inverse_of: :platform_kubernetes, class_name: 'Clusters::Cluster'

      attr_encrypted :password,
        mode: :per_attribute_iv,
        key: Gitlab::Application.secrets.db_key_base,
        algorithm: 'aes-256-cbc'

      attr_encrypted :token,
        mode: :per_attribute_iv,
        key: Gitlab::Application.secrets.db_key_base,
        algorithm: 'aes-256-cbc'

      before_validation :enforce_namespace_to_lower_case

      validates :namespace,
        allow_blank: true,
        length: 1..63,
        format: {
          with: Gitlab::Regex.kubernetes_namespace_regex,
          message: Gitlab::Regex.kubernetes_namespace_regex_message
        }

      # We expect to be `active?` only when enabled and cluster is created (the api_url is assigned)
      validates :api_url, url: true, presence: true
      validates :token, presence: true

      after_save :clear_reactive_cache!

      # TODO: Glue code till we migrate Kubernetes Integration into Platforms::Kubernetes
      after_destroy :destroy_kubernetes_integration!

      alias_attribute :ca_pem, :ca_cert

      delegate :project, to: :cluster, allow_nil: true
      delegate :enabled?, to: :cluster, allow_nil: true

      class << self
        def namespace_for_project(project)
          "#{project.path}-#{project.id}"
        end
      end

      def actual_namespace
        if namespace.present?
          namespace
        else
          default_namespace
        end
      end

      def default_namespace
        self.class.namespace_for_project(project) if project
      end

      def predefined_variables
        config = YAML.dump(kubeconfig)

        variables = [
          { key: 'KUBE_URL', value: api_url, public: true },
          { key: 'KUBE_TOKEN', value: token, public: false },
          { key: 'KUBE_NAMESPACE', value: actual_namespace, public: true },
          { key: 'KUBECONFIG', value: config, public: false, file: true }
        ]

        if ca_pem.present?
          variables << { key: 'KUBE_CA_PEM', value: ca_pem, public: true }
          variables << { key: 'KUBE_CA_PEM_FILE', value: ca_pem, public: true, file: true }
        end

        variables
      end

      # Constructs a list of terminals from the reactive cache
      #
      # Returns nil if the cache is empty, in which case you should try again a
      # short time later
      def terminals(environment)
        with_reactive_cache do |data|
          pods = filter_by_label(data[:pods], app: environment.slug)
          terminals = pods.flat_map { |pod| terminals_for_pod(api_url, actual_namespace, pod) }
          terminals.each { |terminal| add_terminal_auth(terminal, terminal_auth) }
        end
      end

      # Caches resources in the namespace so other calls don't need to block on
      # network access
      def calculate_reactive_cache
        return unless active? && project && !project.pending_delete?

        # We may want to cache extra things in the future
        { pods: read_pods }
      end

      def kubeconfig
        to_kubeconfig(
          url: api_url,
          namespace: actual_namespace,
          token: token,
          ca_pem: ca_pem)
      end

      def read_secrets
        kubeclient = build_kubeclient!

        kubeclient.get_secrets.as_json
      end

      # Returns a hash of all pods in the namespace
      def read_pods
        kubeclient = build_kubeclient!

        kubeclient.get_pods(namespace: actual_namespace).as_json
      rescue KubeException => err
        raise err unless err.error_code == 404
        []
      end

      def kubeclient_ssl_options
        opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

        if ca_pem.present?
          opts[:cert_store] = OpenSSL::X509::Store.new
          opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
        end

        opts
      end

      def kubeclient
        @kubeclient ||= kubernetes_service.kubeclient if manages_kubernetes_service?
      end

      def update_kubernetes_integration!
        raise 'Kubernetes service already configured' unless manages_kubernetes_service?

        # This is neccesary, otheriwse enabled? returns true even though cluster updated with enabled: false
        cluster.reload

        ensure_kubernetes_service&.update!(
          active: enabled?,
          api_url: api_url,
          namespace: namespace,
          token: token,
          ca_pem: ca_cert
        )
      end

      def active?
        manages_kubernetes_service?
      end

      private

      def enforce_namespace_to_lower_case
        self.namespace = self.namespace&.downcase
      end

      # TODO: glue code till we migrate Kubernetes Service into Platforms::Kubernetes class
      def manages_kubernetes_service?
        return true unless kubernetes_service&.active?

        kubernetes_service.api_url == api_url
      end

      def destroy_kubernetes_integration!
        return unless manages_kubernetes_service?

        kubernetes_service&.destroy!
      end

      def kubernetes_service
        @kubernetes_service ||= project&.kubernetes_service
      end

      def ensure_kubernetes_service
        @kubernetes_service ||= kubernetes_service || project&.build_kubernetes_service
      end

      def build_kubeclient!(api_path: 'api', api_version: 'v1')
        raise "Incomplete settings" unless api_url && actual_namespace

        unless (username && password) || token
          raise "Either username/password or token is required to access API"
        end

        ::Kubeclient::Client.new(
          join_api_url(api_path),
          api_version,
          auth_options: kubeclient_auth_options,
          ssl_options: kubeclient_ssl_options,
          http_proxy_uri: ENV['http_proxy']
        )
      end

      def kubeclient_auth_options
        return { username: username, password: password } if username && password
        return { bearer_token: token } if token
      end

      def join_api_url(api_path)
        url = URI.parse(api_url)
        prefix = url.path.sub(%r{/+\z}, '')

        url.path = [prefix, api_path].join("/")

        url.to_s
      end

      def terminal_auth
        {
          token: token,
          ca_pem: ca_pem,
          max_session_time: current_application_settings.terminal_max_session_time
        }
      end

      def enforce_namespace_to_lower_case
        self.namespace = self.namespace&.downcase
      end
    end
  end
end
