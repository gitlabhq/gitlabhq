# frozen_string_literal: true

# https://www.periscopedata.com/blog/medians-in-sql.html
module Gitlab
  module Database
    module Median
      NotSupportedError = Class.new(StandardError)

      def median_datetime(arel_table, query_so_far, column_sym)
        extract_median(execute_queries(arel_table, query_so_far, column_sym)).presence
      end

      def median_datetimes(arel_table, query_so_far, column_sym, partition_column)
        extract_medians(execute_queries(arel_table, query_so_far, column_sym, partition_column)).presence
      end

      def extract_median(results)
        result = results.compact.first

        result = result.first.presence

        result['median']&.to_f if result
      end

      def extract_medians(results)
        median_values = results.compact.first.values

        median_values.each_with_object({}) do |(id, median), hash|
          hash[id.to_i] = median&.to_f
        end
      end

      def pg_median_datetime_sql(arel_table, query_so_far, column_sym, partition_column = nil)
        # Create a CTE with the column we're operating on, row number (after sorting by the column
        # we're operating on), and count of the table we're operating on (duplicated across) all rows
        # of the CTE. For example, if we're looking to find the median of the `projects.star_count`
        # column, the CTE might look like this:
        #
        #  star_count | row_id | ct
        # ------------+--------+----
        #           5 |      1 |  3
        #           9 |      2 |  3
        #          15 |      3 |  3
        #
        #  If a partition column is used we will do the same operation but for separate partitions,
        #  when that happens the CTE might look like this:
        #
        #  project_id | star_count | row_id | ct
        # ------------+------------+--------+----
        #           1 |          5 |     1 |  2
        #           1 |          9 |     2 |  2
        #           2 |         10 |     1 |  3
        #           2 |         15 |     2 |  3
        #           2 |         20 |     3 |  3
        cte_table = Arel::Table.new("ordered_records")

        cte = Arel::Nodes::As.new(
          cte_table,
          arel_table.project(*rank_rows(arel_table, column_sym, partition_column)).
            # Disallow negative values
            where(arel_table[column_sym].gteq(zero_interval)))

        # From the CTE, select either the middle row or the middle two rows (this is accomplished
        # by 'where cte.row_id between cte.ct / 2.0 AND cte.ct / 2.0 + 1'). Find the average of the
        # selected rows, and this is the median value.
        result =
          cte_table
            .project(*median_projections(cte_table, column_sym, partition_column))
            .where(
              Arel::Nodes::Between.new(
                cte_table[:row_id],
                Arel::Nodes::And.new(
                  [(cte_table[:ct] / Arel.sql('2.0')),
                   (cte_table[:ct] / Arel.sql('2.0') + 1)]
                )
              )
            )
            .with(query_so_far, cte)

        result.group(cte_table[partition_column]).order(cte_table[partition_column]) if partition_column

        result.to_sql
      end

      private

      def execute_queries(arel_table, query_so_far, column_sym, partition_column = nil)
        queries = pg_median_datetime_sql(arel_table, query_so_far, column_sym, partition_column)

        Array.wrap(queries).map { |query| ActiveRecord::Base.connection.execute(query) }
      end

      def average(args, as)
        Arel::Nodes::NamedFunction.new("AVG", args, as)
      end

      def rank_rows(arel_table, column_sym, partition_column)
        column_row = arel_table[column_sym].as(column_sym.to_s)

        if partition_column
          partition_row = arel_table[partition_column]
          row_id =
            Arel::Nodes::Over.new(
              Arel::Nodes::NamedFunction.new('rank', []),
              Arel::Nodes::Window.new.partition(arel_table[partition_column])
                .order(arel_table[column_sym])
            ).as('row_id')

          count = arel_table.from.from(arel_table.alias)
                    .project('COUNT(*)')
                    .where(arel_table[partition_column].eq(arel_table.alias[partition_column]))
                    .as('ct')

          [partition_row, column_row, row_id, count]
        else
          row_id =
            Arel::Nodes::Over.new(
              Arel::Nodes::NamedFunction.new('row_number', []),
              Arel::Nodes::Window.new.order(arel_table[column_sym])
            ).as('row_id')

          count = arel_table.where(arel_table[column_sym].gteq(zero_interval)).project("COUNT(1)").as('ct')

          [column_row, row_id, count]
        end
      end

      def median_projections(table, column_sym, partition_column)
        projections = []
        projections << table[partition_column] if partition_column
        projections << average([extract_epoch(table[column_sym])], "median")
        projections
      end

      def extract_epoch(arel_attribute)
        Arel.sql(%Q{EXTRACT(EPOCH FROM "#{arel_attribute.relation.name}"."#{arel_attribute.name}")})
      end

      def extract_diff_epoch(diff)
        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{diff.to_sql}))})
      end

      # Need to cast '0' to an INTERVAL before we can check if the interval is positive
      def zero_interval
        Arel::Nodes::NamedFunction.new("CAST", [Arel.sql("'0' AS INTERVAL")])
      end
    end
  end
end
