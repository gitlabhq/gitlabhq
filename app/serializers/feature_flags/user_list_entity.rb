# frozen_string_literal: true

module FeatureFlags
  class UserListEntity < Grape::Entity
    expose :id
    expose :iid
    expose :name
    expose :user_xids
  end
end
