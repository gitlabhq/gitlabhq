# frozen_string_literal: true

module API
  module Entities
    class Trigger < Grape::Entity
      include ::API::Helpers::Presentable

      expose :id, documentation: { type: 'Integer', example: 10 }
      expose :token, documentation: { type: 'String', example: '6d056f63e50fe6f8c5f8f4aa10edb7' }
      expose :description, documentation: { type: 'String', example: 'test' }
      expose :created_at, documentation: { type: 'DateTime', example: '2015-12-24T15:51:21.880Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2015-12-24T17:54:31.198Z' }
      expose :last_used, documentation: { type: 'DateTime', example: '2015-12-24T17:54:31.198Z' }
      expose :expires_at, documentation: { type: 'DateTime', example: '2015-12-24T17:54:31.198Z' }
      expose :owner, using: Entities::UserBasic
    end
  end
end
