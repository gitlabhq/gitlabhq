# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      class FetchKubernetesTokenService
        attr_reader :kubeclient, :service_account_token_name, :namespace

        def initialize(kubeclient, service_account_token_name, namespace)
          @kubeclient = kubeclient
          @service_account_token_name = service_account_token_name
          @namespace = namespace
        end

        def execute
          token_base64 = get_secret&.dig('data', 'token')
          Base64.decode64(token_base64) if token_base64
        end

        private

        def get_secret
          kubeclient.get_secret(service_account_token_name, namespace).as_json
        rescue Kubeclient::HttpError => err
          raise err unless err.error_code == 404

          nil
        end
      end
    end
  end
end
