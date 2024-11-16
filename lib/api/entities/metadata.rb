# frozen_string_literal: true

module API
  module Entities
    class Metadata < Grape::Entity
      expose :version, documentation: { type: 'string', example: '15.2-pre' }
      expose :revision, documentation: { type: 'string', example: 'c401a659d0c' }
      expose :kas do
        expose :enabled, documentation: { type: 'boolean' }
        expose :externalUrl, documentation: { type: 'string', example: 'grpc://gitlab.example.com:8150' }
        expose :externalK8sProxyUrl, documentation: { type: 'string', example: 'https://gitlab.example.com:8150/k8s-proxy' }
        expose :version, documentation: { type: 'string', example: '15.0.0' }
      end
      expose :enterprise, documentation: { type: 'boolean' }
    end
  end
end
