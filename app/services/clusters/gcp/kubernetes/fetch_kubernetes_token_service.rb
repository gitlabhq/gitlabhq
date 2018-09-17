# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      class FetchKubernetesTokenService
        attr_reader :kubeclient

        def initialize(kubeclient)
          @kubeclient = kubeclient
        end

        def execute
          token_base64 = get_secret&.dig('data', 'token')
          Base64.decode64(token_base64) if token_base64
        end

        private

        def get_secret
          kubeclient.get_secret(SERVICE_ACCOUNT_TOKEN_NAME, SERVICE_ACCOUNT_NAMESPACE).as_json
        rescue Kubeclient::HttpError => err
          raise err unless err.error_code == 404

          nil
        end
      end
    end
  end
end
