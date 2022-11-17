# frozen_string_literal: true

module API
  module Entities
    class DeployToken < Grape::Entity
      # exposing :token is a security risk and should be avoided
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :name, documentation: { type: 'string', example: 'MyToken' }
      expose :username, documentation: { type: 'string', example: 'gitlab+deploy-token-1' }
      expose :expires_at, documentation: { type: 'dateTime', example: '2020-02-14T00:00:00.000Z' }
      expose :scopes, documentation: { type: 'array', example: ['read_repository'] }
      expose :revoked, documentation: { type: 'boolean' }
      expose :expired?, documentation: { type: 'boolean' }, as: :expired
    end
  end
end
