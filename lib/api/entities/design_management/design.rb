# frozen_string_literal: true

module API
  module Entities
    module DesignManagement
      class Design < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :project_id, documentation: { type: 'Integer', example: 1 }
        expose :filename, documentation: { type: 'String', example: 'homescreen.jpg' }
        expose :imported?, as: :imported, documentation: { type: 'Boolean', example: false }
        expose :imported_from, documentation: { type: 'String', example: 'none' }
        expose :image_url, documentation: { type: 'String', example: 'http://example.com/image.png' } do |design|
          ::Gitlab::UrlBuilder.build(design)
        end
      end
    end
  end
end
