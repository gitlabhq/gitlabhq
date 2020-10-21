# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class LegacyScope < Grape::Entity
        expose :id
        expose :active
        expose :environment_scope
        expose :strategies
        expose :created_at
        expose :updated_at
      end
    end
  end
end
