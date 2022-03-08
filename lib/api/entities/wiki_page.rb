# frozen_string_literal: true

module API
  module Entities
    class WikiPage < WikiPageBasic
      include ::MarkupHelper

      expose :content do |wiki_page, options|
        options[:render_html] ? render_wiki_content(wiki_page) : wiki_page.content
      end

      expose :encoding do |wiki_page|
        wiki_page.content.encoding.name
      end
    end
  end
end
