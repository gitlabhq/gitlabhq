# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class BasicUserList < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :iid, documentation: { type: 'Integer', example: 1 }
        expose :name, documentation: { type: 'String', example: 'user_list' }
        expose :user_xids, documentation: { type: 'String', example: 'user1,user2' }
      end
    end
  end
end
