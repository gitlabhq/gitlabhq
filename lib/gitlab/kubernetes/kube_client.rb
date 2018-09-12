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
        'api' => 'v1',
        'apis/rbac.authorization.k8s.io' => 'v1',
        'apis/extensions' => 'v1',
        'apis/serving.knative.dev' => 'v1alpha1'
      }

      # Core API methods delegates to the core api group client
      delegate :get_pods,
        :get_secrets,
        :get_config_map,
        :get_namespace,
        :get_pod,
        :get_service,
        :get_service_account,
        :delete_pod,
        :create_config_map,
        :create_namespace,
        :create_pod,
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

      def initialize(api_prefix, api_groups = ['api'], **kubeclient_options)
        raise ArgumentError, "missing api group" unless check_api_groups_supported?(api_groups)

        @api_prefix = api_prefix
        @api_groups = api_groups
        @kubeclient_options = kubeclient_options
      end

      def discover!
        clients.each(&:discover)
      end

      def clients
        hashed_clients.values
      end

      def core_client
        hashed_clients['api']
      end

      def rbac_client
        hashed_clients['apis/rbac.authorization.k8s.io']
      end

      def extensions_client
        hashed_clients['apis/extensions']
      end

      def serving_client
        hashed_clients['apis/serving.knative.dev']
      end

      def hashed_clients
        strong_memoize(:hashed_clients) do
          @api_groups.map do |api_group|
            api_url = join_api_url(@api_prefix, api_group)
            [api_group, ::Kubeclient::Client.new(api_url, SUPPORTED_API_GROUPS[api_group], **@kubeclient_options)]
          end.to_h
        end
      end

      private

      def check_api_groups_supported?(api_groups)
        api_groups.all? do |api_group|
          SUPPORTED_API_GROUPS[api_group]
        end
      end

      def join_api_url(api_prefix, api_path)
        url = URI.parse(api_prefix)
        prefix = url.path.sub(%r{/+\z}, '')

        url.path = [prefix, api_path].join("/")

        url.to_s
      end
    end
  end
end
