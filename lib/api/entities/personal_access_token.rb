# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessToken < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 2 }
      expose :name, documentation: { type: 'string', example: 'John Doe' }
      expose :revoked, documentation: { type: 'boolean' }
      expose :created_at, documentation: { type: 'dateTime' }
      expose :description, documentation: { type: 'string', example: 'Token to manage api' }
      expose :scopes, documentation: { type: 'array', example: ['api'] }
      expose :user_id, documentation: { type: 'integer', example: 3 }
      expose :last_used_at, documentation: { type: 'dateTime', example: '2020-08-31T15:53:00.073Z' }
      expose :active?, as: :active, documentation: { type: 'boolean' }
      expose :expires_at, documentation:
        { type: 'dateTime', example: '2020-08-31T15:53:00.073Z' } do |personal_access_token|
        personal_access_token.expires_at ? personal_access_token.expires_at.iso8601 : nil
      end
    end
  end
end
