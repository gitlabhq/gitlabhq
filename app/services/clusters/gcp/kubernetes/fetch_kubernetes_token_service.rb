# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      class FetchKubernetesTokenService
        attr_reader :kubeclient, :service_account_name

        def initialize(kubeclient, service_account_name)
          @kubeclient = kubeclient
          @service_account_name = service_account_name
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
          /#{service_account_name}-token/
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
