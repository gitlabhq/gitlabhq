# frozen_string_literal: true

module TestEntities
  class UserEntity < Grape::Entity
    expose :id, documentation: { type: 'integer', format: 'int64', desc: 'User ID' }
    expose :name, documentation: { type: 'string', desc: 'User name' }
    expose :email, documentation: { type: 'string', format: 'email', desc: 'User email' }
    expose :created_at, documentation: { type: 'dateTime', desc: 'Date and time of creation' }
    expose :updated_at, documentation: { type: 'dateTime', desc: 'Date and time of last update' }
  end
end
