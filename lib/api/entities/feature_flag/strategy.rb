# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class Strategy < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :name, documentation: { type: 'String', example: 'userWithId' }
        expose :parameters, documentation: { type: 'String', example: '{"userIds": "user1"}' }
        expose :scopes, using: FeatureFlag::Scope
        expose :user_list, using: FeatureFlag::BasicUserList
      end
    end
  end
end
