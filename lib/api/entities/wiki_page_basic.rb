# frozen_string_literal: true

module API
  module Entities
    class WikiPageBasic < Grape::Entity
      expose :format, documentation: { type: 'string', example: 'markdown' }
      expose :slug, documentation: { type: 'string', example: 'deploy' }
      expose :title, documentation: { type: 'string', example: 'deploy' }

      expose :wiki_page_meta_id, documentation: { type: 'integer', example: { wiki_page_meta_id: 123 } } do |wiki_page|
        wiki_page.find_or_create_meta.id
      end
    end
  end
end
