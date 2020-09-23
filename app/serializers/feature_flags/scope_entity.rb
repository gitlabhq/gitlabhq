# frozen_string_literal: true

module FeatureFlags
  class ScopeEntity < Grape::Entity
    expose :id
    expose :environment_scope
  end
end
