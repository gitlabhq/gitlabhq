# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    class FeatureMatchService
      VALID_PANELS = %w[project group].freeze
      MIN_QUERY_LENGTH = 2

      def initialize(query:, panel:, user: nil, resource: nil)
        @query = query
        @panel = panel.to_s
        @user = user
        @resource = resource
      end

      def execute
        return [] unless VALID_PANELS.include?(panel)

        normalized = normalize(query)

        entries = ranked_entries(normalized) # Tier 1: whole-query match

        if entries.any?
          self.tracking_label = 'exact_map'
        else
          entries = keyword_entries(normalized) # Tier 2: tokenized match, only on Tier 1 miss
          self.tracking_label = entries.any? ? 'keyword_extract' : 'no_match'
        end

        entries.map { |e| e['feature_key'] } # rubocop:disable Rails/Pluck -- entries is a plain Array, not an ActiveRecord relation
               .uniq
      end

      def ai_execute
        return [] unless VALID_PANELS.include?(panel)

        ai_gateway_ids(normalize(query))
      end

      # Overridden in EE
      def ai_search_enabled?
        false
      end

      # Overridden in EE
      def ai_search_available?
        false
      end

      private

      attr_reader :query, :panel, :user, :resource
      attr_accessor :tracking_label

      # Overridden in EE
      def ai_gateway_ids(_normalized_query)
        []
      end

      def normalize(query)
        query.to_s.downcase.strip
      end

      # Tier 1: matches the full normalized query against terms,
      # ranked: exact term match, then prefix, then substring.
      def ranked_entries(normalized_query)
        return [] if normalized_query.length < MIN_QUERY_LENGTH

        exact = []
        starts = []
        contains = []

        Onboarding::FeatureLibrary::TerminologyMap.all.each do |entry| # rubocop:disable Rails/FindEach -- iterating a frozen Array, not an ActiveRecord relation
          next unless Array(entry['panels']).include?(panel)

          term = entry['term']
          next unless term.include?(normalized_query)

          if term == normalized_query
            exact << entry
          elsif term.start_with?(normalized_query)
            starts << entry
          else
            contains << entry
          end
        end

        (exact + starts + contains)
      end

      # Tier 2: No stemming: morphological variants (e.g. "branches" vs "branch") fall through to Tier 3.
      def keyword_entries(normalized_query)
        tokens = normalized_query.split
                                 .reject { |t| Gitlab::Search::AbuseDetection::STOP_WORDS.include?(t) }

        tokens.flat_map { |token| ranked_entries(token) }
              .uniq { |e| [e['feature_key'], e['panels']] }
      end
    end
  end
end

Onboarding::FeatureLibrary::FeatureMatchService.prepend_mod
