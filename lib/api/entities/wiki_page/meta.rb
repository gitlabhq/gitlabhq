# frozen_string_literal: true

module API
  module Entities
    class WikiPage
      class Meta < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 2 }
        expose :canonical_slug, as: :slug, documentation: { type: 'String', example: 'home' }
        expose :title, documentation: { type: 'String', example: 'Page title' }
      end
    end
  end
end
