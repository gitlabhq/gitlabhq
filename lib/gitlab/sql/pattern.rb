# frozen_string_literal: true

module Gitlab
  module SQL
    module Pattern
      extend ActiveSupport::Concern

      MIN_CHARS_FOR_PARTIAL_MATCHING = 3
      REGEX_QUOTED_TERM = /(?<=\A| )"[^"]+"(?= |\z)/

      class_methods do
        def fuzzy_search(query, columns, use_minimum_char_limit: true, exact_matches_first: false)
          matches = columns.map do |col|
            fuzzy_arel_match(col, query, use_minimum_char_limit: use_minimum_char_limit)
          end.compact.reduce(:or)

          matches = where(matches)

          return matches unless exact_matches_first

          matches.order(exact_matches_first_sql(query, columns))
        end

        def exact_matches_first_sql(query, columns)
          cases_sql = columns.map do |column|
            arel_column = column.is_a?(Arel::Attributes::Attribute) ? column : arel_table[column]
            match_sql = arel_column.matches(sanitize_sql_like(query)).to_sql
            "WHEN #{match_sql} THEN 1"
          end

          cases_sql << "ELSE 2"

          Arel.sql("CASE\n#{cases_sql.join("\n")}\nEND")
        end

        def to_pattern(query, use_minimum_char_limit: true)
          if partial_matching?(query, use_minimum_char_limit: use_minimum_char_limit)
            "%#{sanitize_sql_like(query)}%"
          else
            sanitize_sql_like(query)
          end
        end

        def min_chars_for_partial_matching
          MIN_CHARS_FOR_PARTIAL_MATCHING
        end

        def partial_matching?(query, use_minimum_char_limit: true)
          return true unless use_minimum_char_limit

          query.length >= min_chars_for_partial_matching
        end

        # column - The column name / Arel column to search in.
        # query - The text to search for.
        # lower_exact_match - When set to `true` we'll fall back to using
        #                     `LOWER(column) = query` instead of using `ILIKE`.
        def fuzzy_arel_match(column, query, lower_exact_match: false, use_minimum_char_limit: true)
          return unless query.is_a?(String)

          query = query.squish
          return unless query.present?

          arel_column = column.is_a?(Arel::Attributes::Attribute) ? column : arel_table[column]

          words = select_fuzzy_terms(query, use_minimum_char_limit: use_minimum_char_limit)

          if words.any?
            words.map { |word| arel_column.matches(to_pattern(word, use_minimum_char_limit: use_minimum_char_limit)) }.reduce(:and)
          elsif lower_exact_match
            # No words of at least 3 chars, but we can search for an exact
            # case insensitive match with the query as a whole
            Arel::Nodes::NamedFunction
                .new('LOWER', [arel_column])
                .eq(query)
          else
            arel_column.matches(sanitize_sql_like(query))
          end
        end

        def select_fuzzy_terms(query, use_minimum_char_limit: true)
          terms = Gitlab::SQL::Pattern.split_query_to_search_terms(query)
          terms.select { |term| partial_matching?(term, use_minimum_char_limit: use_minimum_char_limit) }
        end
      end

      def self.split_query_to_search_terms(query)
        quoted_terms = []

        query = query.gsub(REGEX_QUOTED_TERM) do |quoted_term|
          quoted_terms << quoted_term
          ""
        end

        query.split + quoted_terms.map { |quoted_term| quoted_term[1..-2] }
      end
    end
  end
end

Gitlab::SQL::Pattern.prepend_mod
Gitlab::SQL::Pattern::ClassMethods.prepend_mod_with('Gitlab::SQL::Pattern::ClassMethods')
