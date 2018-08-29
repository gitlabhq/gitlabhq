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
          read_secrets.each do |secret|
            name = secret.dig('metadata', 'name')
            if token_regex =~ name
              token_base64 = secret.dig('data', 'token')
              return Base64.decode64(token_base64) if token_base64
            end
          end

          nil
        end

        private

        def token_regex
          /#{SERVICE_ACCOUNT_NAME}-token/
        end

        def read_secrets
          kubeclient.get_secrets.as_json
        rescue Kubeclient::HttpError => err
          raise err unless err.error_code == 404

          []
        end
      end
    end
  end
end
