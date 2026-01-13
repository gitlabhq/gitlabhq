# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessToken < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 2 }
      expose :name, documentation: { type: 'String', example: 'John Doe' }
      expose :revoked, documentation: { type: 'Boolean' }
      expose :created_at, documentation: { type: 'DateTime' }
      expose :description, documentation: { type: 'String', example: 'Token to manage api' }
      expose :scopes, documentation: { type: 'Array', example: ['api'] }
      expose :user_id, documentation: { type: 'Integer', example: 3 }
      expose :last_used_at, documentation: { type: 'DateTime', example: '2020-08-31T15:53:00.073Z' }
      expose :active?, as: :active, documentation: { type: 'Boolean' }
      expose :expires_at, documentation:
        { type: 'DateTime', example: '2020-08-31T15:53:00.073Z' } do |personal_access_token|
        personal_access_token.expires_at ? personal_access_token.expires_at.iso8601 : nil
      end
    end
  end
end
