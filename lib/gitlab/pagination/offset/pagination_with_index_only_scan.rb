# frozen_string_literal: true

module Gitlab
  module Pagination
    module Offset
      # rubocop: disable CodeReuse/ActiveRecord -- Generic code for pagination
      #
      # This class can build optimized offset queries where we try to force the DB to use
      # index-only-scan for skipping the OFFSET rows by selecting the columns in the ORDER BY clause explicitly.
      # The selected rows will be fully loaded from the table using a LATERAL SELECT.
      #
      # The class can be used with any ActiveRecord scope however, the optimization will be only applied when:
      # - `ORDER BY` clause is present
      # - The columns in an `ORDER BY` point to one distinct record -> the `ORDER BY` clause can be keyset paginated
      #
      # Usage:
      #
      # scope = Issue.where(project_id: 1).order(:id)
      #
      # records = PaginationWithIndexOnlyScan.new(scope: scope, page: 5, per_page: 100).paginate_with_kaminari
      # puts records.to_a
      # puts records.total_count
      class PaginationWithIndexOnlyScan
        CTE_NAME = :index_only_scan_pagination_cte
        SUBQUERY_NAME = :index_only_scan_subquery

        def initialize(scope:, page:, per_page:)
          @scope = scope
          @page = page
          @per_page = per_page
          @model = scope.model
          @original_order_values = scope.order_values
        end

        def paginate_with_kaminari
          original_kaminari_query = scope.page(page).per(per_page)

          # Check for keyset pagination support
          if keyset_aware_scope && (keyset_order_by_columns.size == original_order_by_columns.size)
            original_kaminari_query.extend(build_module_for_load)
          end

          original_kaminari_query
        end

        private

        attr_reader :scope, :page, :per_page, :model, :original_order_values

        def build_module_for_load
          optimized_scope = build_optimized_scope
            .includes(scope.includes_values)
            .preload(scope.preload_values)
            .eager_load(scope.eager_load_values)
            .select(scope.select_values)

          # Extend the current ActiveRecord::Relation and override the load method where we
          # use our optimized query to load the actual records.
          #
          # Reason 1: total_count query
          #
          # Kaminari uses the given scope to build the count query for calculating the total
          # number of pages. This data will be used on the UI and also in the REST API for providing
          # pagination headers. By only modifying the `load` method, the `COUNT` query is not
          # going to change which is desired since the "original" `COUNT` query is more efficient.
          #
          # Reason 2: preserving offset value
          #
          # The optimized query has the ORDER BY, LIMIT and OFFSET clauses in a subquery which
          # makes building the correct pagination headers impossible. Kaminari calls offset_value
          # and limit_value on the original scope.
          Module.new do
            define_method :load do |&block|
              if !loaded? || scheduled?
                @records = optimized_scope.to_a
                @loaded = true
              end

              super(&block)
            end
          end
        end

        def build_optimized_scope
          index_only_scan_query = Arel::Table.new(CTE_NAME)
            .project(*keyset_order_by_columns.map(&:attribute_name))
            .as(SUBQUERY_NAME.to_s)
            .to_sql

          row_loader_query = select_rows_from_cte
          from = [
            index_only_scan_query,
            "LATERAL (#{row_loader_query.to_sql}) #{model.quoted_table_name}"
          ].join(', ')

          build_cte
            .apply_to(model.where({}))
            .from(from)
        end

        def select_rows_from_cte
          inner_table = Arel::Table.new(SUBQUERY_NAME)
          lateral_scope = model.limit(1).select(scope.select_values)

          keyset_order_by_columns.each do |column|
            eq_condition = column.column_expression.eq(inner_table[column.attribute_name])

            # If the column is nullable we have to do two lookups:
            # - use = filter to handle the case where the selected value is not NULL
            # - use IS NULL filter to handle the case where the selected value is NULL
            lateral_scope = if column.nullable?
                              not_null_condition = Arel::Nodes::And.new([
                                eq_condition,
                                inner_table[column.attribute_name].not_eq(nil)
                              ])

                              null_condition = Arel::Nodes::And.new([
                                column.column_expression.eq(nil),
                                inner_table[column.attribute_name].eq(nil)
                              ])

                              conditions = Arel::Nodes::Grouping.new([
                                Arel::Nodes::Or.new(not_null_condition, null_condition)
                              ])

                              lateral_scope.where(conditions)
                            else
                              lateral_scope.where(eq_condition)
                            end
          end

          lateral_scope
        end

        def build_cte
          select_list = keyset_order_by_columns.map do |column|
            column.column_expression.as(column.attribute_name)
          end

          inner_scope = keyset_aware_scope.reselect(*select_list)
          # Build kaminari-based offset-pagination, ideally this should make an index only scan
          inner_scope = inner_scope.page(page).per(per_page)

          Gitlab::SQL::CTE.new(CTE_NAME, inner_scope)
        end

        def keyset_aware_scope
          return @keyset_aware_scope if defined?(@keyset_aware_scope)

          order, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder
            .new(scope: scope)
            .build_order

          @keyset_aware_scope = scope.reorder(order) if success
        end

        def keyset_order
          @keyset_order ||= Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(keyset_aware_scope)
        end

        def keyset_order_by_columns
          keyset_order.column_definitions
        end

        def original_order_by_columns
          if original_order_values.first.is_a?(Gitlab::Pagination::Keyset::Order) && original_order_values.one?
            original_order_values.first.column_definitions
          else
            original_order_values
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
