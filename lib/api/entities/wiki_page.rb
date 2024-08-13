# frozen_string_literal: true

module API
  module Entities
    class WikiPage < WikiPageBasic
      include ::MarkupHelper

      expose :content, documentation: {
        type: 'string', example: 'Here is an instruction how to deploy this project.'
      } do |wiki_page, options|
        if options[:render_html]
          render_wiki_content(
            wiki_page,
            ref: wiki_page.version.id,
            current_user: options[:current_user]
          )
        else
          wiki_page.raw_content
        end
      end

      expose :encoding, documentation: { type: 'string', example: 'UTF-8' } do |wiki_page|
        wiki_page.content.encoding.name
      end

      expose :front_matter, documentation: { type: 'Hash', example: { title: "deploy" } }
    end
  end
end

API::Entities::WikiPage.prepend_mod
