# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        # rubocop: disable CodeReuse/ActiveRecord
        class QueryBuilder
          RECURSIVE_CTE_NAME = 'recursive_keyset_cte'

          # This class optimizes slow database queries (PostgreSQL specific) where the
          # IN SQL operator is used with sorting.
          #
          # Arguments:
          # scope - ActiveRecord::Relation supporting keyset pagination
          # array_scope - ActiveRecord::Relation for the `IN` subselect
          # array_mapping_scope - Lambda for connecting scope with array_scope
          # finder_query - ActiveRecord::Relation for finding one row by the passed in cursor values
          # values - keyset cursor values (optional)
          #
          # Example ActiveRecord query: Issues in the namespace hierarchy
          # > scope = Issue
          # >  .where(project_id: Group.find(9970).all_projects.select(:id))
          # >  .order(:created_at, :id)
          # >  .limit(20);
          #
          # Optimized version:
          #
          # > scope = Issue.where({}).order(:created_at, :id) # base scope
          # > array_scope = Group.find(9970).all_projects.select(:id)
          # > array_mapping_scope = -> (id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
          #
          # # finding the record by id is good enough, we can ignore the created_at_expression
          # > finder_query = -> (created_at_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
          #
          # > Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
          # >   scope: scope,
          # >   array_scope: array_scope,
          # >   array_mapping_scope: array_mapping_scope,
          # >   finder_query: finder_query
          # > ).execute.limit(20)
          def initialize(scope:, array_scope:, array_mapping_scope:, finder_query: nil, values: {})
            @scope, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope)

            raise(UnsupportedScopeOrder) unless success

            @order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
            @array_scope = array_scope
            @array_mapping_scope = array_mapping_scope
            @values = values
            @model = @scope.model
            @table_name = @model.table_name
            @arel_table = @model.arel_table
            @finder_strategy = finder_query.present? ? Strategies::RecordLoaderStrategy.new(finder_query, model, order_by_columns) : Strategies::OrderValuesLoaderStrategy.new(model, order_by_columns)
          end

          def execute
            selector_cte = Gitlab::SQL::CTE.new(:array_cte, array_scope)

            cte = Gitlab::SQL::RecursiveCTE.new(RECURSIVE_CTE_NAME, union_args: { remove_duplicates: false, remove_order: false })
            cte << initializer_query
            cte << data_collector_query

            q = cte
              .apply_to(model.where({})
              .with(selector_cte.to_arel))
              .select(finder_strategy.final_projections)
              .where("count <> 0") # filter out the initializer row

            model.select(Arel.star).from(q.arel.as(table_name))
          end

          private

          attr_reader :array_scope, :scope, :order, :array_mapping_scope, :finder_strategy, :values, :model, :table_name, :arel_table

          def initializer_query
            array_column_names = array_scope_columns.array_aggregated_column_names + order_by_columns.array_aggregated_column_names

            projections = [
              *finder_strategy.initializer_columns,
              *array_column_names,
              '0::bigint AS count'
            ]

            model.select(projections).from(build_column_arrays_query).limit(1)
          end

          # This query finds the first cursor values for each item in the array CTE.
          #
          # array_cte:
          #
          # |project_id|
          # |----------|
          # |         1|
          # |         2|
          # |         3|
          # |         4|
          #
          # For each project_id, find the first issues row by respecting the created_at, id order.
          #
          # The `array_mapping_scope` parameter defines how the `array_scope` and the `scope` can be combined.
          #
          # scope = Issue.where({}) # empty scope
          # array_mapping_scope = Issue.where(project_id: X)
          #
          # scope.merge(array_mapping_scope) # Issue.where(project_id: X)
          #
          # X will be replaced with a value from the `array_cte` temporary table.
          #
          # |created_at|id|
          # |----------|--|
          # |2020-01-15| 2|
          # |2020-01-07| 3|
          # |2020-01-07| 4|
          # |2020-01-10| 5|
          def build_column_arrays_query
            q = Arel::SelectManager.new
              .project(array_scope_columns.array_aggregated_columns + order_by_columns.array_aggregated_columns)
              .from(array_cte)
              .join(Arel.sql("LEFT JOIN LATERAL (#{initial_keyset_query.to_sql}) #{table_name} ON TRUE"))

            order_by_columns.each { |c| q.where(c.column_expression.not_eq(nil)) unless c.column.nullable? }

            q.as('array_scope_lateral_query')
          end

          def array_cte
            Arel::SelectManager.new
              .project(array_scope_columns.arel_columns)
              .from(Arel.sql(array_scope_columns.array_scope_cte_name))
              .as(array_scope_columns.array_scope_cte_name)
          end

          def initial_keyset_query
            keyset_scope = scope.merge(array_mapping_scope.call(*array_scope_columns.arel_columns))
            order
              .apply_cursor_conditions(keyset_scope, values, use_union_optimization: true)
              .reselect(*order_by_columns.arel_columns)
              .limit(1)
          end

          def data_collector_query
            array_column_list = array_scope_columns.array_aggregated_column_names

            order_column_value_arrays = order_by_columns.replace_value_in_array_by_position_expressions

            select = [
              *finder_strategy.columns,
              *array_column_list,
              *order_column_value_arrays,
              "#{RECURSIVE_CTE_NAME}.count + 1"
            ]

            from = <<~SQL
              #{RECURSIVE_CTE_NAME},
              #{array_order_query.lateral.as('position_query').to_sql},
              #{ensure_one_row(next_cursor_values_query).lateral.as('next_cursor_values').to_sql}
            SQL

            model.select(select).from(from)
          end

          # NULL guard. This method ensures that NULL values are returned when the passed in scope returns 0 rows.
          # Example query: returns issues.id or NULL
          #
          # SELECT issues.id FROM (VALUES (NULL)) nulls (id)
          # LEFT JOIN (SELECT id FROM issues WHERE id = 1 LIMIT 1) issues ON TRUE
          # LIMIT 1
          def ensure_one_row(query)
            q = Arel::SelectManager.new
            q.projections = order_by_columns.original_column_names_as_tmp_tamble

            null_values = [nil] * order_by_columns.count

            from = Arel::Nodes::Grouping.new(Arel::Nodes::ValuesList.new([null_values])).as('nulls')

            q.from(from)
            q.join(Arel.sql("LEFT JOIN (#{query.to_sql}) record ON TRUE"))
            q.limit = 1
            q
          end

          # This subquery finds the cursor values for the next record by sorting the generated cursor arrays in memory and taking the first element.
          # It combines the cursor arrays (UNNEST) together and sorts them according to the originally defined ORDER BY clause.
          #
          # Example: issues in the group hierarchy with ORDER BY created_at, id
          #
          # |project_id|  |created_at|id| # 2 arrays combined: issues_created_at_array, issues_id_array
          # |----------|  |----------|--|
          # |         1|  |2020-01-15| 2|
          # |         2|  |2020-01-07| 3|
          # |         3|  |2020-01-07| 4|
          # |         4|  |2020-01-10| 5|
          #
          # The query will return the cursor values: (2020-01-07, 3) and the array position: 1
          # From the position, we can tell that the record belongs to the project with id 2.
          def array_order_query
            q = Arel::SelectManager.new
              .project([*order_by_columns.original_column_names_as_arel_string, Arel.sql('position')])
              .from("UNNEST(#{list(order_by_columns.array_aggregated_column_names)}) WITH ORDINALITY AS u(#{list(order_by_columns.original_column_names)}, position)")

            order_by_columns.each { |c| q.where(Arel.sql(c.original_column_name).not_eq(nil)) unless c.column.nullable? } # ignore rows where all columns are NULL

            q.order(Arel.sql(order_by_without_table_references)).take(1)
          end

          # This subquery finds the next cursor values after the previously determined position (from array_order_query).
          # The current cursor values are passed in as SQL literals since the actual values are encoded into SQL arrays.
          #
          # Example: issues in the group hierarchy with ORDER BY created_at, id
          #
          # |project_id|  |created_at|id| # 2 arrays combined: issues_created_at_array, issues_id_array
          # |----------|  |----------|--|
          # |         1|  |2020-01-15| 2|
          # |         2|  |2020-01-07| 3|
          # |         3|  |2020-01-07| 4|
          # |         4|  |2020-01-10| 5|
          #
          # Assuming that the determined position is 1, the cursor values will be the following:
          # - Filter: project_id = 2
          # - created_at = 2020-01-07
          # - id = 3
          def next_cursor_values_query
            cursor_values = order_by_columns.cursor_values(RECURSIVE_CTE_NAME)
            array_mapping_scope_columns = array_scope_columns.array_lookup_expressions_by_position(RECURSIVE_CTE_NAME)

            keyset_scope = scope
              .reselect(*order_by_columns.arel_columns)
              .merge(array_mapping_scope.call(*array_mapping_scope_columns))

            order
              .apply_cursor_conditions(keyset_scope, cursor_values, use_union_optimization: true)
              .reselect(*order_by_columns.map(&:column_for_projection))
              .limit(1)
          end

          # Generates an ORDER BY clause by using the column position index and the original order clauses.
          # This method is used to sort the collected arrays in SQL.
          # Example: "issues".created_at DESC , "issues".id ASC => 1 DESC, 2 ASC
          def order_by_without_table_references
            order.column_definitions.each_with_index.map do |column_definition, i|
              "#{i + 1} #{column_definition.order_direction_as_sql_string}"
            end.join(", ")
          end

          def array_scope_columns
            @array_scope_columns ||= ArrayScopeColumns.new(array_scope.select_values)
          end

          def order_by_columns
            @order_by_columns ||= OrderByColumns.new(order.column_definitions, arel_table)
          end

          def list(array)
            array.join(', ')
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
