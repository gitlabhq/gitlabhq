# frozen_string_literal: true

module Routing
  module WikiHelper
    def wiki_path(wiki, **options)
      Gitlab::UrlBuilder.wiki_url(wiki, only_path: true, **options)
    end

    def wiki_page_path(wiki, page, **options)
      Gitlab::UrlBuilder.wiki_page_url(wiki, page, only_path: true, **options)
    end
  end
end
