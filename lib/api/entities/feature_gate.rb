# frozen_string_literal: true

module API
  module Entities
    class FeatureGate < Grape::Entity
      expose :key, documentation: { type: 'String', example: 'percentage_of_actors' }
      expose :value, documentation: { type: 'Integer', example: 34 }
    end
  end
end
