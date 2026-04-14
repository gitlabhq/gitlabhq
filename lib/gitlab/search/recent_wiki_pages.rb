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
    end
  end
end
