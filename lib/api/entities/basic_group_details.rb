# frozen_string_literal: true

module API
  module Entities
    class BasicGroupDetails < Grape::Entity
      expose :id, documentation: { type: 'Integer' }
      expose :web_url, documentation: { type: 'String', example: 'http://gitlab.example.com/groups/diaspora' }
      expose :name, documentation: { type: 'String', example: 'Diaspora' }
    end
  end
end
