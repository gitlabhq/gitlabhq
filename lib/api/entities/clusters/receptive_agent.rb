# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class ReceptiveAgent < Grape::Entity
        expose :agent_id, as: :id
        expose :url
        expose :ca_cert
        expose :tls_host
        expose :jwt
        expose :mtls

        def jwt
          return unless object.private_key

          { private_key: Base64.strict_encode64(object.private_key) }
        end

        def mtls
          return unless object.client_key && object.client_cert

          {
            client_key: object.client_key,
            client_cert: object.client_cert
          }
        end
      end
    end
  end
end
