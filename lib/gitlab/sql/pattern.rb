module Gitlab
  module SQL
    class Pattern
      MIN_CHARS_FOR_PARTIAL_MATCHING = 3

      attr_reader :query

      def initialize(query)
        @query = query
      end

      def to_sql
        if exact_matching?
          query
        else
          "%#{query}%"
        end
      end

      def exact_matching?
        !partial_matching?
      end

      def partial_matching?
        @query.length >= MIN_CHARS_FOR_PARTIAL_MATCHING
      end
    end
  end
end
