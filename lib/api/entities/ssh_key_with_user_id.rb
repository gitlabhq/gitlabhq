# frozen_string_literal: true

module API
  module Entities
    class SshKeyWithUserId < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :title, documentation: { type: 'string', example: 'Sample key 25' }
      expose :created_at, documentation: { type: 'dateTime', example: '2015-09-03T07:24:44.627Z' }
      expose :expires_at, documentation: { type: 'dateTime', example: '2020-09-03T07:24:44.627Z' }
      expose :last_used_at, documentation: { type: 'dateTime', example: '2020-09-03T07:24:44.627Z' }
      expose :usage_type, documentation: { type: 'string', example: 'auth' }
      expose :user_id, documentation: { type: 'integer', example: 3 }
    end
  end
end
