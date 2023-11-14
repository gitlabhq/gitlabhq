# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch < Base
        SetOperatorStarError = Class.new(QueryAnalyzerError)

        DETECT_REGEX = /.*SELECT.+(UNION|EXCEPT|INTERSECT)/i

        class << self
          def enabled?
            ::Feature::FlipperFeature.table_exists? &&
              Feature.enabled?(:query_analyzer_gitlab_schema_metrics, type: :ops)
          end

          def analyze(parsed)
            return unless requires_detection?(parsed.sql)

            # Only handle SELECT queries.
            parsed.pg.tree.stmts.each do |stmt|
              select_stmt = next_select_stmt(stmt)
              next unless select_stmt

              types = SelectStmt.new(select_stmt).types

              raise SetOperatorStarError if types.any?(Type::INVALID)
            end
          end

          private

          def next_select_stmt(node)
            return unless node.stmt.respond_to?(:select_stmt)

            node.stmt.select_stmt
          end

          # This not entirely correct and will run true on `SELECT union_station, ...`
          def requires_detection?(sql)
            sql.match DETECT_REGEX
          end
        end
      end
    end
  end
end
