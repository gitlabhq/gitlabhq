# frozen_string_literal: true

module API
  module Entities
    class FeatureGate < Grape::Entity
      expose :key, documentation: { type: 'string', example: 'percentage_of_actors' }
      expose :value, documentation: { type: 'integer', example: 34 }
    end
  end
end
