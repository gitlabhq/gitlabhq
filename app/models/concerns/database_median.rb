module DatabaseMedian
  extend ActiveSupport::Concern

  def median_datetime(arel_table, query_so_far, column_sym)
    # TODO: MySQL
    pg_median_datetime(arel_table, query_so_far, column_sym)
  end


  # https://www.periscopedata.com/blog/medians-in-sql.html
  def pg_median_datetime(arel_table, query_so_far, column_sym)
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
    cte_table = Arel::Table.new(("ordered_records"))
    cte = Arel::Nodes::As.new(cte_table,
                              arel_table.
                                project(arel_table[column_sym].as(column_sym.to_s),
                                                 Arel::Nodes::Over.new(Arel::Nodes::NamedFunction.new("row_number", []),
                                                                       Arel::Nodes::Window.new.order(arel_table[column_sym])).as('row_id'),
                                                 arel_table.project("COUNT(1)").as('ct')).
                                # Disallow negative values
                                where(arel_table[column_sym].gteq(zero_interval)))

    # From the CTE, select either the middle row or the middle two rows (this is accomplished
    # by 'where cte.row_id between cte.ct / 2.0 AND cte.ct / 2.0 + 1'). Find the average of the
    # selected rows, and this is the median value.
    cte_table.project(Arel::Nodes::NamedFunction.new("AVG",
                                                     [extract_epoch(cte_table[column_sym])],
                                                     "median")).
      where(Arel::Nodes::Between.new(cte_table[:row_id],
                                     Arel::Nodes::And.new([(cte_table[:ct] / Arel::Nodes::SqlLiteral.new('2.0')),
                                                           (cte_table[:ct] / Arel::Nodes::SqlLiteral.new('2.0') + 1)]))).
      with(query_so_far, cte)
  end

  private

  def extract_epoch(arel_attribute)
    Arel::Nodes::SqlLiteral.new("EXTRACT(EPOCH FROM \"#{arel_attribute.relation.name}\".\"#{arel_attribute.name}\")")
  end

  # Need to cast '0' to an INTERVAL before we can check if the interval is positive
  def zero_interval
    Arel::Nodes::NamedFunction.new("CAST", [Arel::Nodes::SqlLiteral.new("'0' AS INTERVAL")])
  end
end
