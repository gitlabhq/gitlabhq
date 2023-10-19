# frozen_string_literal: true

# References form the base data structure of the PreventSetOperatorMismatch query analyzer.
#
# A reference refers to a table, CTE, or other named entity in a SQL query. References are a set of mappings between the
# name of the reference and the PgQuery node that represents that reference in the parsed tree.
#
# Given the SQL:
#
# WITH some_cte AS (SELECT 1)
# SELECT *
# FROM some_cte, users, namespace ns
#
# The reference names would be `some_cte`, `users`, `ns`. The reference values are the nodes in the parse tree that
# represent that reference:
# - some_cte: the common table expression node
# - users: nil, being a table
# - ns: nil, being a table, but importantly we use the alias name
#
# A reference can be "resolved". A resolved reference value is a Set of Types. The reference value was a select
# statement that has since been parsed.
module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        class References
          class << self
            # All references that have already been parsed to determine static/dynamic/error state.
            # @param [Hash] refs A Hash of reference names mapped to the parse tree node or resolved Set of Types.
            def resolved(refs)
              refs.select { |_name, ref| ref.is_a?(Set) }
            end

            # All references that have not been parsed to determine static/dynamic/error state.
            # @param [Hash] refs A Hash of reference names mapped to the parse tree node or resolved Set of Types.
            def unresolved(refs)
              refs.select { |_name, ref| unresolved?(ref) }
            end

            # Whether any currently resolved references have resulted in an error state.
            # @param [Hash] refs A Hash of reference names mapped to the parse tree node or resolved Set of Types.
            def errors?(refs)
              resolved(refs).any? { |_, values| values.include?(Type::INVALID) }
            end

            private

            def resolved?(ref)
              ref.is_a?(Set)
            end

            def unresolved?(ref)
              !resolved?(ref) && table?(ref)
            end

            def table?(ref)
              !ref.is_a?(PgQuery::RangeVar)
            end
          end
        end
      end
    end
  end
end
