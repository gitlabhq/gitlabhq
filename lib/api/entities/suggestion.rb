# frozen_string_literal: true

module API
  module Entities
    class Suggestion < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :from_line, documentation: { type: 'Integer', example: 1 }
      expose :to_line, documentation: { type: 'Integer', example: 1 }
      expose :appliable?, as: :appliable, documentation: { type: 'Boolean', example: true }
      expose :applied, documentation: { type: 'Boolean', example: false }
      expose :from_content, documentation: { type: 'String', example: "Original content\n" }
      expose :to_content, documentation: { type: 'String', example: "New content\n" }
    end
  end
end
