# frozen_string_literal: true

module Gitlab
  module HookData
    class WikiPageBuilder < BaseBuilder
      alias_method :wiki_page, :object

      def build
        wiki_page
          .attributes
          .merge(
            'content' => absolute_image_urls(wiki_page.content)
          )
      end

      def uploads_prefix
        wiki_page.wiki.wiki_base_path
      end
    end
  end
end
