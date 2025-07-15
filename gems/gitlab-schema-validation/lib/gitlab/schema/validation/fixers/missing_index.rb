# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Fixers
        class MissingIndex < Base
          def statement
            parsed = PgQuery.parse(structure_sql_statement)
            index_stmt = parsed.tree.stmts.first.stmt.index_stmt
            index_stmt.concurrent = true
            parsed.deparse
          end
        end
      end
    end
  end
end
