# frozen_string_literal: true

module API
  module Entities
    class LabelBasic < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :name, documentation: { type: 'String', example: 'bug' }
      expose :description, documentation: { type: 'String', example: 'Bug reported by user' }
      expose :text_color, documentation: { type: 'String', example: '#FFFFFF' }

      expose :description_html, documentation: { type: 'String', example: '<p>Bug reported by user</p>' } do |label|
        MarkupHelper.markdown_field(label, :description, current_user: options[:current_user])
      end

      expose :color, documentation: { type: 'String', example: '#FF0000' } do |label, options|
        label.color.to_s
      end

      expose :archived, documentation: { type: 'Boolean', example: false }
    end
  end
end
