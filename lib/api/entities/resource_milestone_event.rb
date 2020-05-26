# frozen_string_literal: true

module API
  module Entities
    class ResourceMilestoneEvent < Grape::Entity
      expose :id
      expose :user, using: Entities::UserBasic
      expose :created_at
      expose :resource_type do |event, _options|
        event.issuable.class.name
      end
      expose :resource_id do |event, _options|
        event.issuable.id
      end
      expose :milestone, using: Entities::Milestone
      expose :action
      expose :state
    end
  end
end
