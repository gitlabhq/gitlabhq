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
          sanitized_query
        else
          "%#{sanitized_query}%"
        end
      end

      def exact_matching?
        !partial_matching?
      end

      def partial_matching?
        @query.length >= MIN_CHARS_FOR_PARTIAL_MATCHING
      end

      def sanitized_query
        # Note: ActiveRecord::Base.sanitize_sql_like is a protected method
        ActiveRecord::Base.__send__(:sanitize_sql_like, query)
      end
    end
  end
end
