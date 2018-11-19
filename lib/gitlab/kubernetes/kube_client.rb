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
        core: { group: 'api', version: 'v1' },
        rbac: { group: 'apis/rbac.authorization.k8s.io', version: 'v1' },
        extensions: { group: 'apis/extensions', version: 'v1beta1' },
        knative: { group: 'apis/serving.knative.dev', version: 'v1alpha1' }
      }.freeze

      SUPPORTED_API_GROUPS.each do |name, params|
        client_method_name = "#{name}_client".to_sym

        define_method(client_method_name) do
          strong_memoize(client_method_name) do
            build_kubeclient(params[:group], params[:version])
          end
        end
      end

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

      # RBAC methods delegates to the apis/rbac.authorization.k8s.io api
      # group client
      delegate :create_role_binding,
        :get_role_binding,
        :update_role_binding,
        to: :rbac_client

      # Deployments resource is currently on the apis/extensions api group
      delegate :get_deployments,
        to: :extensions_client

      # non-entity methods that can only work with the core client
      # as it uses the pods/log resource
      delegate :get_pod_log,
        :watch_pod_log,
        to: :core_client

      attr_reader :api_prefix, :kubeclient_options

      def initialize(api_prefix, **kubeclient_options)
        @api_prefix = api_prefix
        @kubeclient_options = kubeclient_options
      end

      private

      def build_kubeclient(api_group, api_version)
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
    end
  end
end
