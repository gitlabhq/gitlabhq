# frozen_string_literal: true

module API
  module Entities
    class CustomAttribute < Grape::Entity
      expose :key, documentation: { type: 'String', example: 'foo' }
      expose :value, documentation: { type: 'String', example: 'bar' }
    end
  end
end
