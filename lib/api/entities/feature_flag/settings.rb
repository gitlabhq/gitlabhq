# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class Settings < Grape::Entity
        expose :feature_flags_minimum_role,
          as: :minimum_role,
          documentation: { type: 'String', example: 'developer' }
      end
    end
  end
end
