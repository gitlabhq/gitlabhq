# frozen_string_literal: true

module Clusters
  module Kubernetes
    class FetchKubernetesTokenService
      DEFAULT_TOKEN_RETRY_DELAY = 5.seconds
      TOKEN_RETRY_LIMIT = 5

      attr_reader :kubeclient, :service_account_token_name, :namespace

      def initialize(kubeclient, service_account_token_name, namespace, token_retry_delay: DEFAULT_TOKEN_RETRY_DELAY)
        @kubeclient = kubeclient
        @service_account_token_name = service_account_token_name
        @namespace = namespace
        @token_retry_delay = token_retry_delay
      end

      def execute
        # Kubernetes will create the Secret and set the token asynchronously
        # so it is necessary to retry
        # https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#token-controller
        TOKEN_RETRY_LIMIT.times do
          token_base64 = get_secret&.dig('data', 'token')
          return Base64.decode64(token_base64) if token_base64

          sleep @token_retry_delay
        end

        nil
      end

      private

      def get_secret
        kubeclient.get_secret(service_account_token_name, namespace).as_json
      rescue Kubeclient::ResourceNotFoundError
      end
    end
  end
end
