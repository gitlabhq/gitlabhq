# frozen_string_literal: true

module API
  module Entities
    class WikiPage < WikiPageBasic
      expose :content

      expose :encoding do |wiki_page|
        wiki_page.content.encoding.name
      end
    end
  end
end
