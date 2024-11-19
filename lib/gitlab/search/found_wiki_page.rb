# frozen_string_literal: true

# - rendering by using data purely from Elasticsearch and does not trigger Gitaly calls.
# - allows policy check
module Gitlab
  module Search
    class FoundWikiPage < SimpleDelegator
      attr_reader :wiki

      delegate :container, to: :wiki

      def self.declarative_policy_class
        'WikiPagePolicy'
      end

      # @param found_blob [Gitlab::Search::FoundBlob]
      def initialize(found_blob)
        super

        @wiki ||= found_blob.project.wiki
      end

      def to_ability_name
        'wiki_page'
      end
    end
  end
end

Gitlab::Search::FoundWikiPage.prepend_mod_with('Gitlab::Search::FoundWikiPage')
