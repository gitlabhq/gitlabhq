module Gitlab
  module SQL
    module Pattern
      extend ActiveSupport::Concern

      MIN_CHARS_FOR_PARTIAL_MATCHING = 3

      class_methods do
        def to_pattern(query)
          if exact_matching?(query)
            sanitize_sql_like(query)
          else
            "%#{sanitize_sql_like(query)}%"
          end
        end

        def exact_matching?(query)
          query.length < MIN_CHARS_FOR_PARTIAL_MATCHING
        end

        def partial_matching?(query)
          query.length >= MIN_CHARS_FOR_PARTIAL_MATCHING
        end
      end
    end
  end
end
