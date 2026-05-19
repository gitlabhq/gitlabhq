# frozen_string_literal: true

module API
  module Entities
    class ResourceStateEvent < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 142 }
      expose :user, using: ::API::Entities::UserBasic
      expose :created_at, documentation: { type: 'DateTime', example: '2018-08-20T13:38:20.077Z' }
      expose :resource_type, documentation: { type: 'String', example: 'Issue' } do |event, _options|
        event.issuable.class.name
      end
      expose :resource_id, documentation: { type: 'Integer', example: 253 } do |event, _options|
        event.issuable.id
      end
      expose :source_commit, documentation: { type: 'String', example: '7b09ce7e6f80347baf0316c8c94cdba9a0a7e91d' }
      expose :source_merge_request_id, documentation: { type: 'Integer', example: 45 }
      expose :state, documentation: { type: 'String', example: 'opened' }
    end
  end
end
