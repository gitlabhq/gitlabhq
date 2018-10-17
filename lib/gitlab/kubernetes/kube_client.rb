# frozen_string_literal: true

require 'uri'

module Gitlab
  module Kubernetes
    # Wrapper around Kubeclient::Client to dispatch
    # the right message to the client that can respond to the message.
    # We must have a kubeclient for each ApiGroup as there is no
    # other way to use the Kubeclient gem.
    #
    # See https://github.com/abonas/kubeclient/issues/348.
    class KubeClient
      include Gitlab::Utils::StrongMemoize

      SUPPORTED_API_GROUPS = {
        core: 'api',
        rbac: 'apis/rbac.authorization.k8s.io',
        extensions: 'apis/extensions'
      }.freeze

      LATEST_EXTENSIONS_VERSION = 'v1beta1'

      # Core API methods delegates to the core api group client
      delegate :get_pods,
        :get_secrets,
        :get_config_map,
        :get_namespace,
        :get_pod,
        :get_secret,
        :get_service,
        :get_service_account,
        :delete_pod,
        :create_config_map,
        :create_namespace,
        :create_pod,
        :create_secret,
        :create_service_account,
        :update_config_map,
        :update_service_account,
        to: :core_client

      # RBAC methods delegates to the apis/rbac.authorization.k8s.io api
      # group client
      delegate :create_cluster_role_binding,
        :get_cluster_role_binding,
        :update_cluster_role_binding,
        to: :rbac_client

      # Deployments resource is currently on the apis/extensions api group
      delegate :get_deployments,
        to: :extensions_client

      # non-entity methods that can only work with the core client
      # as it uses the pods/log resource
      delegate :get_pod_log,
        :watch_pod_log,
        to: :core_client

      attr_reader :api_prefix, :kubeclient_options, :default_api_version

      def initialize(api_prefix, default_api_version = 'v1', **kubeclient_options)
        @api_prefix = api_prefix
        @kubeclient_options = kubeclient_options
        @default_api_version = default_api_version
      end

      def core_client(api_version: default_api_version)
        core_clients[api_version]
      end

      def rbac_client(api_version: default_api_version)
        rbac_clients[api_version]
      end

      def extensions_client(api_version: LATEST_EXTENSIONS_VERSION)
        extensions_clients[api_version]
      end

      private

      def build_client(cache_name, api_group)
        strong_memoize(cache_name) do
          Hash.new do |hash, api_version|
            hash[api_version] = build_kubeclient(api_group, api_version)
          end
        end
      end

      def build_kubeclient(api_group, api_version)
        raise ArgumentError, "Unknown api group #{api_group}" unless SUPPORTED_API_GROUPS.values.include?(api_group)

        ::Kubeclient::Client.new(
          join_api_url(api_prefix, api_group),
          api_version,
          **kubeclient_options
        )
      end

      def join_api_url(api_prefix, api_path)
        url = URI.parse(api_prefix)
        prefix = url.path.sub(%r{/+\z}, '')

        url.path = [prefix, api_path].join("/")

        url.to_s
      end

      SUPPORTED_API_GROUPS.each do |name, api_group|
        clients_method_name = "#{name}_clients".to_sym

        define_method(clients_method_name) do
          strong_memoize(clients_method_name.to_sym) do
            Hash.new do |hash, api_version|
              hash[api_version] = build_kubeclient(api_group, api_version)
            end
          end
        end
      end
    end
  end
end
