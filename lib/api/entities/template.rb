# frozen_string_literal: true

module API
  module Entities
    class Template < Grape::Entity
      expose :name, documentation: { type: 'String', example: 'Ruby' }
      expose :content, documentation: { type: 'String', example: '# Ruby gitignore template' }
    end
  end
end
