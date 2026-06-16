# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      class LinkedResource < Grape::Entity
        expose :url, documentation: { type: 'String', example: 'https://example.zoom.us/j/123456789' }
      end
    end
  end
end
