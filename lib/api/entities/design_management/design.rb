# frozen_string_literal: true

module API
  module Entities
    module DesignManagement
      class Design < Grape::Entity
        expose :id
        expose :project_id
        expose :filename
        expose :imported?, as: :imported, documentation: { type: 'boolean', example: false }
        expose :imported_from, documentation: { type: 'string', example: 'none' }
        expose :image_url do |design|
          ::Gitlab::UrlBuilder.build(design)
        end
      end
    end
  end
end
