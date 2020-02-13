# frozen_string_literal: true

module API
  module Entities
    class ResourceLabelEvent < Grape::Entity
      expose :id
      expose :user, using: Entities::UserBasic
      expose :created_at
      expose :resource_type do |event, options|
        event.issuable.class.name
      end
      expose :resource_id do |event, options|
        event.issuable.id
      end
      expose :label, using: Entities::LabelBasic
      expose :action
    end
  end
end
