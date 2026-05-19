# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      # Methods that are commonly used between analyzers
      class QueryAnalyzerHelpers
        VIEW_NODES = [:view_stmt, :create_table_as_stmt].freeze

        class << self
          def dml_from_create_view?(parsed)
            parsed.pg.tree.stmts.select { |stmts| VIEW_NODES.include?(stmts.stmt.node) }.any?
          end
        end
      end
    end
  end
end
