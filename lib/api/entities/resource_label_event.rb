# frozen_string_literal: true

module API
  module Entities
    class ResourceLabelEvent < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 142 }
      expose :user, using: ::API::Entities::UserBasic
      expose :created_at, documentation: { type: 'DateTime', example: '2018-08-20T13:38:20.077Z' }
      expose :resource_type, documentation: { type: 'String', example: 'Issue' } do |event, _options|
        event.issuable.class.name
      end
      expose :resource_id, documentation: { type: 'Integer', example: 253 } do |event, _options|
        event.issuable.id
      end
      expose :label, using: ::API::Entities::LabelBasic
      expose :action, documentation: { type: 'String', example: 'add' }
    end
  end
end
