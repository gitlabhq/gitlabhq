# frozen_string_literal: true

module FeatureFlags
  class StrategyEntity < Grape::Entity
    expose :id
    expose :name
    expose :parameters
    expose :scopes, with: FeatureFlags::ScopeEntity
    expose :user_list, with: FeatureFlags::UserListEntity, expose_nil: false
  end
end
