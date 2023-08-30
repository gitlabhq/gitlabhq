# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class BasicUserList < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :iid, documentation: { type: 'integer', example: 1 }
        expose :name, documentation: { type: 'string', example: 'user_list' }
        expose :user_xids, documentation: { type: 'string', example: 'user1,user2' }
      end
    end
  end
end
