# frozen_string_literal: true

module API
  module Entities
    class TemplatesList < Grape::Entity
      expose :key, documentation: { type: 'String', example: 'mit' }
      expose :name, documentation: { type: 'String', example: 'MIT License' }
    end
  end
end
