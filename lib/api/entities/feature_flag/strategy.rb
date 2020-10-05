# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class Strategy < Grape::Entity
        expose :id
        expose :name
        expose :parameters
        expose :scopes, using: FeatureFlag::Scope
      end
    end
  end
end
