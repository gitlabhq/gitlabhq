# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      class Label < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :title, documentation: { type: 'String', example: 'bug' }
        expose :description, documentation: { type: 'String', example: 'Bug reports' }
        expose :color, documentation: { type: 'String', example: '#FF0000' } do |label|
          label.color.to_s
        end
        expose :text_color, documentation: { type: 'String', example: '#FFFFFF' }
      end
    end
  end
end
