# frozen_string_literal: true

module API
  module Entities
    class TemplatesList < Grape::Entity
      expose :key, documentation: { type: 'string', example: 'mit' }
      expose :name, documentation: { type: 'string', example: 'MIT License' }
    end
  end
end
