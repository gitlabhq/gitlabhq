module Gitlab
  module SQL
    module Pattern
      extend ActiveSupport::Concern

      MIN_CHARS_FOR_PARTIAL_MATCHING = 3
      REGEX_QUOTED_WORD = /(?<=^| )"[^"]+"(?= |$)/

      class_methods do
        def to_pattern(query)
          if partial_matching?(query)
            "%#{sanitize_sql_like(query)}%"
          else
            sanitize_sql_like(query)
          end
        end

        def partial_matching?(query)
          query.length >= MIN_CHARS_FOR_PARTIAL_MATCHING
        end

        def to_fuzzy_arel(column, query)
          words = select_fuzzy_words(query)

          matches = words.map { |word| arel_table[column].matches(to_pattern(word)) }

          matches.reduce { |result, match| result.and(match) }
        end

        def select_fuzzy_words(query)
          quoted_words = query.scan(REGEX_QUOTED_WORD)

          query = quoted_words.reduce(query) { |q, quoted_word| q.sub(quoted_word, '') }

          words = query.split(/\s+/)

          quoted_words.map! { |quoted_word| quoted_word[1..-2] }

          words.concat(quoted_words)

          words.select { |word| partial_matching?(word) }
        end
      end
    end
  end
end
