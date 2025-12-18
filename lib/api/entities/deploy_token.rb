# frozen_string_literal: true

module API
  module Entities
    class DeployToken < Grape::Entity
      # exposing :token is a security risk and should be avoided
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :name, documentation: { type: 'String', example: 'MyToken' }
      expose :username, documentation: { type: 'String', example: 'gitlab+deploy-token-1' }
      expose :expires_at, documentation: { type: 'DateTime', example: '2020-02-14T00:00:00.000Z' }
      expose :scopes, documentation: { type: 'Array', example: ['read_repository'] }
      expose :revoked, documentation: { type: 'Boolean' }
      expose :expired?, documentation: { type: 'Boolean' }, as: :expired
    end
  end
end
