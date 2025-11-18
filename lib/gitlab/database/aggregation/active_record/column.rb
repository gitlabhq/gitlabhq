# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        # Represents a SELECT-able column or SQL expression
        # - name: name of the column or a name for the expression
        # - type: defines the data type of the returned column values. Most cases this matches with the
        # database column's type
        # - expression (optional): Arel node for defining more complex SQL expressions
        # - scope_proc (optional): hook for modifying the underlying ActiveRecord scope, for
        # example joining one extra table.
        # - formatter (optional): how to format the data, the formatter is invoked before the
        # values are casted to the defined type.
        # - description (optional): user friendly description of the column
        #
        # Example: simple column selection
        #
        # > c = Gitlab::Database::Aggregation::ActiveRecord::Column.new(:id, Integer)
        # > scope = Issue.where(project_id: 1)
        # > scope.select(c.to_arel({ arel_table: Issue.arel_table })).to_sql
        # # SELECT "issues"."id" FROM "issues" WHERE "issues"."project_id" = 1
        #
        # Example: custom SQL expression
        # > expression = -> { Arel.sql("('id_' || id + 10)") } # string: id_20
        # > c = Gitlab::Database::Aggregation::ActiveRecord::Column.new(:id_plus_ten_prefixed, String,
        # >   expression: expression)
        # > scope = Issue.where(project_id: 1)
        # > scope.select(c.to_arel({ arel_table: Issue.arel_table })).to_sql
        # # SELECT ('id_' || id + 10) FROM "issues" WHERE "issues"."project_id" = 1
        #
        # Example: use a column from a JOIN-ed table
        # > e = -> { Issue::Metrics.arel_table[:first_added_to_board_at] }
        # > s = -> (scope, _ctx) { scope.joins(:metrics) }
        # > c = Gitlab::Database::Aggregation::ActiveRecord::Column.new(:first_added_to_board_at, String,
        #   expression: e, scope_proc: s)
        # > scope = Issue.where(project_id: 1)
        # > scope = c.apply_scope(scope, nil) # This will be invoked by the aggregation engine
        # > scope.select(c.to_arel({ arel_table: Issue.arel_table })).to_sql
        # # SELECT "issue_metrics"."first_added_to_board_at" FROM "issues"
        # # INNER JOIN "issue_metrics" ON "issue_metrics"."issue_id" = "issues"."id"
        # # WHERE "issues"."project_id" = 1
        class Column
          attr_reader :name, :type, :expression, :scope_proc, :formatter, :description

          def initialize(name, type, expression: nil, formatter: nil, scope_proc: nil, description: nil)
            @name = name
            @type = type
            @expression = expression
            @formatter = formatter
            @scope_proc = scope_proc
            @description = description
          end

          def identifier
            :"column_#{name}"
          end

          def to_hash
            {
              identifier: identifier,
              name: name,
              type: type,
              kind: :column,
              description: description
            }
          end

          def format(val)
            formatter ? formatter.call(val) : val
          end

          def apply_scope(scope, context)
            scope_proc ? scope_proc.call(scope, context) : scope
          end

          def to_arel(context)
            expression ? expression.call : context[:arel_table][name]
          end
        end
      end
    end
  end
end
