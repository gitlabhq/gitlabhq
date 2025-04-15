# frozen_string_literal: true

module API
  module Entities
    class WikiPage
      class Meta < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 2 }
        expose :canonical_slug, as: :slug, documentation: { type: 'string', example: 'home' }
        expose :title, documentation: { type: 'string', example: 'Page title' }
      end
    end
  end
end
