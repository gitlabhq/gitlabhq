# frozen_string_literal: true

module API
  module Entities
    class CustomAttribute < Grape::Entity
      expose :key, documentation: { type: 'string', example: 'foo' }
      expose :value, documentation: { type: 'string', example: 'bar' }
    end
  end
end
