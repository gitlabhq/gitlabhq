# frozen_string_literal: true

module API
  module Entities
    class ResourceStateEvent < Grape::Entity
      expose :id
      expose :user, using: Entities::UserBasic
      expose :created_at
      expose :resource_type do |event, _options|
        event.issuable.class.name
      end
      expose :resource_id do |event, _options|
        event.issuable.id
      end
      expose :source_commit
      expose :source_merge_request_id
      expose :state
    end
  end
end
