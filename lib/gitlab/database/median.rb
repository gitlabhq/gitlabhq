# https://www.periscopedata.com/blog/medians-in-sql.html
module Gitlab
  module Database
    module Median
      def median_datetimes(arel_table, query_so_far, column_sym, partition_column)
        median_queries =
          if Gitlab::Database.postgresql?
            pg_median_datetime_sql(arel_table, query_so_far, column_sym, partition_column)
          elsif Gitlab::Database.mysql?
            mysql_median_datetime_sql(arel_table, query_so_far, column_sym)
          end

        results = Array.wrap(median_queries).map do |query|
          ActiveRecord::Base.connection.execute(query)
        end
        extract_medians(results).presence
      end

      def extract_medians(results)
        result = results.compact.first

        if Gitlab::Database.postgresql?
          result.values.map do |id, median|
            [id.to_i, median&.to_f]
          end.to_h
        elsif Gitlab::Database.mysql?
          result.to_a.flatten.first
        end
      end

      def mysql_median_datetime_sql(arel_table, query_so_far, column_sym)
        query = arel_table
                .from(arel_table.project(Arel.sql('*')).order(arel_table[column_sym]).as(arel_table.table_name))
                .project(average([arel_table[column_sym]], 'median'))
                .where(
                  Arel::Nodes::Between.new(
                    Arel.sql("(select @row_id := @row_id + 1)"),
                    Arel::Nodes::And.new(
                      [Arel.sql('@ct/2.0'),
                       Arel.sql('@ct/2.0 + 1')]
                    )
                  )
                ).
                # Disallow negative values
                where(arel_table[column_sym].gteq(0))

        [
          Arel.sql("CREATE TEMPORARY TABLE IF NOT EXISTS #{query_so_far.to_sql}"),
          Arel.sql("set @ct := (select count(1) from #{arel_table.table_name});"),
          Arel.sql("set @row_id := 0;"),
          query.to_sql,
          Arel.sql("DROP TEMPORARY TABLE IF EXISTS #{arel_table.table_name};")
        ]
      end

      def pg_median_datetime_sql(arel_table, query_so_far, column_sym, partition_column)
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
        cte_table = Arel::Table.new("ordered_records")
        cte = Arel::Nodes::As.new(
          cte_table,
          arel_table
            .project(
              arel_table[partition_column],
              arel_table[column_sym].as(column_sym.to_s),
              Arel::Nodes::Over.new(Arel::Nodes::NamedFunction.new("rank", []),
                                    Arel::Nodes::Window.new.partition(arel_table[partition_column])
                                      .order(arel_table[column_sym])).as('row_id'),
              arel_table.from(arel_table.alias)
                .project("COUNT(*)")
                .where(arel_table[partition_column].eq(arel_table.alias[partition_column])).as('ct')).
            # Disallow negative values
            where(arel_table[column_sym].gteq(zero_interval)))

        # From the CTE, select either the middle row or the middle two rows (this is accomplished
        # by 'where cte.row_id between cte.ct / 2.0 AND cte.ct / 2.0 + 1'). Find the average of the
        # selected rows, and this is the median value.
        cte_table
          .project(cte_table[partition_column])
          .project(average([extract_epoch(cte_table[column_sym])], "median"))
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
          .group(cte_table[partition_column])
          .order(cte_table[partition_column])
          .to_sql
      end

      private

      def average(args, as)
        Arel::Nodes::NamedFunction.new("AVG", args, as)
      end

      def extract_epoch(arel_attribute)
        Arel.sql(%Q{EXTRACT(EPOCH FROM "#{arel_attribute.relation.name}"."#{arel_attribute.name}")})
      end

      def extract_diff_epoch(diff)
        return diff unless Gitlab::Database.postgresql?

        Arel.sql(%Q{EXTRACT(EPOCH FROM (#{diff.to_sql}))})
      end

      # Need to cast '0' to an INTERVAL before we can check if the interval is positive
      def zero_interval
        Arel::Nodes::NamedFunction.new("CAST", [Arel.sql("'0' AS INTERVAL")])
      end
    end
  end
end
