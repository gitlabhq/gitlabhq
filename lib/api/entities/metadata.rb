# frozen_string_literal: true

module API
  module Entities
    class Metadata < Grape::Entity
      expose :version, documentation: { type: 'String', example: '15.2-pre' }
      expose :revision, documentation: { type: 'String', example: 'c401a659d0c' }
      expose :kas do
        expose :enabled, documentation: { type: 'Boolean' }
        expose :externalUrl, documentation: { type: 'String', example: 'grpc://gitlab.example.com:8150' }
        expose :externalK8sProxyUrl, documentation: { type: 'String', example: 'https://gitlab.example.com:8150/k8s-proxy' }
        expose :version, documentation: { type: 'String', example: '15.0.0' }
      end
      expose :enterprise, documentation: { type: 'Boolean' }
    end
  end
end
