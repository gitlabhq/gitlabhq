# frozen_string_literal: true

module Gitlab
  module Search
    class ParsedQuery
      include Gitlab::Utils::StrongMemoize

      attr_reader :term, :filters

      def initialize(term, filters)
        @term = term
        @filters = filters
      end

      def filter_results(results)
        with_matcher = ->(filter) { filter[:matcher].present? }

        excluding = excluding_filters.select(&with_matcher)
        including = including_filters.select(&with_matcher)

        return unless excluding.any? || including.any?

        results.select! do |result|
          including.all? { |filter| filter[:matcher].call(filter, result) }
        end

        results.reject! do |result|
          excluding.any? { |filter| filter[:matcher].call(filter, result) }
        end

        results
      end

      private

      def including_filters
        processed_filters(:including)
      end

      def excluding_filters
        processed_filters(:excluding)
      end

      def processed_filters(type)
        excluding, including = strong_memoize(:processed_filters) do
          filters.partition { |filter| filter[:negated] }
        end

        case type
        when :including then including
        when :excluding then excluding
        else
          raise ArgumentError, type
        end
      end
    end
  end
end

Gitlab::Search::ParsedQuery.prepend_mod_with('Gitlab::Search::ParsedQuery')
