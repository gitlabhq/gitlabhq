# frozen_string_literal: true

module Gitlab
  module Search
    class RecentWikiPages < RecentItems # rubocop:disable Search/NamespacedClass -- Follows existing RecentItems subclass conventions
      private

      def type
        WikiPage::Meta
      end

      def finder
        Wikis::PageMetaFinder
      end

      def match_title(items, term)
        items.search_by_title(term)
      end
    end
  end
end
