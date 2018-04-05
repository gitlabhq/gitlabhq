module Clusters
  module Platforms
    class Kubernetes < ActiveRecord::Base
      include Gitlab::Kubernetes
      include ReactiveCaching

      self.table_name = 'cluster_platforms_kubernetes'
      self.reactive_cache_key = ->(kubernetes) { [kubernetes.class.model_name.singular, kubernetes.id] }

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

      validate :prevent_modification, on: :update

      after_save :clear_reactive_cache!

      alias_attribute :ca_pem, :ca_cert

      delegate :project, to: :cluster, allow_nil: true
      delegate :enabled?, to: :cluster, allow_nil: true
      delegate :managed?, to: :cluster, allow_nil: true

      alias_method :active?, :enabled?

      def actual_namespace
        if namespace.present?
          namespace
        else
          default_namespace
        end
      end

      def predefined_variables
        config = YAML.dump(kubeconfig)

        Gitlab::Ci::Variables::Collection.new.tap do |variables|
          variables
            .append(key: 'KUBE_URL', value: api_url)
            .append(key: 'KUBE_TOKEN', value: token, public: false)
            .append(key: 'KUBE_NAMESPACE', value: actual_namespace)
            .append(key: 'KUBECONFIG', value: config, public: false, file: true)

          if ca_pem.present?
            variables
              .append(key: 'KUBE_CA_PEM', value: ca_pem)
              .append(key: 'KUBE_CA_PEM_FILE', value: ca_pem, file: true)
          end
        end
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
        return unless enabled? && project && !project.pending_delete?

        # We may want to cache extra things in the future
        { pods: read_pods }
      end

      def kubeclient
        @kubeclient ||= build_kubeclient!
      end

      private

      def kubeconfig
        to_kubeconfig(
          url: api_url,
          namespace: actual_namespace,
          token: token,
          ca_pem: ca_pem)
      end

      def default_namespace
        return unless project

        slug = "#{project.path}-#{project.id}".downcase
        slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
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

      # Returns a hash of all pods in the namespace
      def read_pods
        kubeclient = build_kubeclient!

        kubeclient.get_pods(namespace: actual_namespace).as_json
      rescue Kubeclient::HttpError => err
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

      def kubeclient_auth_options
        { bearer_token: token }
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
          max_session_time: Gitlab::CurrentSettings.terminal_max_session_time
        }
      end

      def enforce_namespace_to_lower_case
        self.namespace = self.namespace&.downcase
      end

      def prevent_modification
        return unless managed?

        if api_url_changed? || token_changed? || ca_pem_changed?
          errors.add(:base, _('Cannot modify managed Kubernetes cluster'))
          return false
        end

        true
      end
    end
  end
end
