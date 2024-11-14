# frozen_string_literal: true

module EachBatch
  extend ActiveSupport::Concern
  include LooseIndexScan

  class_methods do
    # Iterates over the rows in a relation in batches, similar to Rails'
    # `in_batches` but in a more efficient way.
    #
    # Unlike `in_batches` provided by Rails this method does not support a
    # custom start/end range, nor does it provide support for the `load:`
    # keyword argument.
    #
    # This method will yield an ActiveRecord::Relation to the supplied block, or
    # return an Enumerator if no block is given.
    #
    # Example:
    #
    #     User.each_batch do |relation|
    #       relation.update_all(updated_at: Time.current)
    #     end
    #
    # The supplied block is also passed an optional batch index:
    #
    #     User.each_batch do |relation, index|
    #       puts index # => 1, 2, 3, ...
    #     end
    #
    # You can also specify an alternative column to use for ordering the rows:
    #
    #     User.each_batch(column: :created_at) do |relation|
    #       ...
    #     end
    #
    # This will produce SQL queries along the lines of:
    #
    #     User Load (0.7ms)  SELECT  "users"."id" FROM "users" WHERE ("users"."id" >= 41654)
    #                        ORDER BY "users"."id" ASC LIMIT 1 OFFSET 1000
    #       (0.7ms)  SELECT COUNT(*) FROM "users" WHERE ("users"."id" >= 41654) AND ("users"."id" < 42687)
    #
    # of - The number of rows to retrieve per batch.
    # column - The column to use for ordering the batches.
    # order_hint - An optional column to append to the `ORDER BY id`
    #   clause to help the query planner. PostgreSQL might perform badly
    #   with a LIMIT 1 because the planner is guessing that scanning the
    #   index in ID order will come across the desired row in less time
    #   it will take the planner than using another index. The
    #   order_hint does not affect the search results. For example,
    #   `ORDER BY id ASC, updated_at ASC` means the same thing as `ORDER
    #   BY id ASC`.
    def each_batch(of: 1000, column: primary_key, order: :asc, order_hint: nil, reset_order: true)
      unless column
        raise ArgumentError,
          'the column: argument must be set to a column name to use for ordering rows'
      end

      order_with = reset_order ? :reorder : :order

      start = except(:select, :includes, :preload)
        .select(column)
        .method(order_with).call(column => order)

      start = start.order(order_hint) if order_hint
      start = start.take

      return unless start

      start_id = start[column]
      arel_table = self.arel_table

      1.step do |index|
        start_cond = arel_table[column].gteq(start_id)
        start_cond = arel_table[column].lteq(start_id) if order == :desc
        stop = except(:select, :includes, :preload)
          .select(column)
          .where(start_cond)
          .method(order_with).call(column => order)

        stop = stop.order(order_hint) if order_hint
        stop = stop
          .offset(of)
          .limit(1)
          .take

        relation = where(start_cond)

        if stop
          stop_id = stop[column]
          start_id = stop_id
          stop_cond = arel_table[column].lt(stop_id)
          stop_cond = arel_table[column].gt(stop_id) if order == :desc
          relation = relation.where(stop_cond)
        end

        # Any ORDER BYs are useless for this relation and can lead to less
        # efficient UPDATE queries, hence we get rid of it.
        relation = relation.except(:order)

        # Using unscoped is necessary to prevent leaking the current scope used by
        # ActiveRecord to chain `each_batch` method.
        unscoped { yield relation, index }

        break unless stop
      end
    end

    # Iterates over the rows in a relation in batches by skipping duplicated values in the column.
    # Example: counting the number of distinct authors in `issues`
    #
    #  - Table size: 100_000
    #  - Column: author_id
    #  - Distinct author_ids in the table: 1000
    #
    #  The query will read maximum 1000 rows if we have index coverage on user_id.
    #
    #  > count = 0
    #  > Issue.distinct_each_batch(column: 'author_id', of: 1000) { |r| count += r.count(:author_id) }
    def distinct_each_batch(column:, order: :asc, of: 1000)
      start = except(:select)
        .select(column)
        .reorder(column => order)

      start = start.take

      return unless start

      start_id = start[column]
      arel_table = self.arel_table
      arel_column = arel_table[column.to_s]

      1.step do |index|
        stop = loose_index_scan(column: column, order: order) do |cte_query, inner_query|
          if order == :asc
            [cte_query.where(arel_column.gteq(start_id)), inner_query]
          else
            [cte_query.where(arel_column.lteq(start_id)), inner_query]
          end
        end.offset(of).take

        if stop
          stop_id = stop[column]

          relation = loose_index_scan(column: column, order: order) do |cte_query, inner_query|
            if order == :asc
              [cte_query.where(arel_column.gteq(start_id)), inner_query.where(arel_column.lt(stop_id))]
            else
              [cte_query.where(arel_column.lteq(start_id)), inner_query.where(arel_column.gt(stop_id))]
            end
          end
          start_id = stop_id
        else
          relation = loose_index_scan(column: column, order: order) do |cte_query, inner_query|
            if order == :asc
              [cte_query.where(arel_column.gteq(start_id)), inner_query]
            else
              [cte_query.where(arel_column.lteq(start_id)), inner_query]
            end
          end
        end

        unscoped { yield relation, index }

        break unless stop
      end
    end

    # Iterates over the relation and counts the rows. The counting
    # logic is combined with the iteration query which saves one query
    # compared to a standard each_batch approach.
    #
    # Basic usage:
    # count, _last_value = Project.each_batch_count
    #
    # The counting can be stopped by passing a block and making the last statement true.
    # Example:
    #
    # query_count = 0
    # count, last_value = Project.each_batch_count do
    #   query_count += 1
    #   query_count == 5 # stop counting after 5 loops
    # end
    #
    # Resume where the previous counting has stopped:
    #
    # count, last_value = Project.each_batch_count(last_count: count, last_value: last_value)
    #
    # Another example, counting issues in project:
    #
    # project = Project.find(1)
    # count, _ = project.issues.each_batch_count(column: :iid)
    def each_batch_count(of: 1000, column: :id, last_count: 0, last_value: nil)
      arel_table = self.arel_table
      window = Arel::Nodes::Window.new.order(arel_table[column])
      last_value_column = Arel::Nodes::NamedFunction
        .new('LAST_VALUE', [arel_table[column]])
        .over(window)
        .as(column.to_s)

      loop do
        count_column = Arel::Nodes::Addition
          .new(Arel::Nodes::NamedFunction.new('ROW_NUMBER', []).over(window), last_count)
          .as('count')

        projections = [count_column, last_value_column]
        scope = limit(1).offset(of - 1)
        scope = scope.where(arel_table[column].gt(last_value)) if last_value
        new_count, last_value = scope.pick(*projections)

        # When reaching the last batch the offset query might return no data, to address this
        # problem, we invoke a specialized query that takes the last row out of the resultset.
        # We could do this for each batch, however it would add unnecessary overhead to all
        # queries.
        if new_count.nil?
          inner_query = scope
            .select(*projections)
            .limit(nil)
            .offset(nil)
            .arel
            .as(quoted_table_name)

          new_count, last_value =
            unscoped
            .from(inner_query)
            .unscope(where: :type)
            .order(count: :desc)
            .limit(1)
            .pick(:count, column)

          last_count = new_count if new_count
          last_value = nil
          break
        end

        last_count = new_count

        if block_given?
          should_break = yield(last_count, last_value)
          break if should_break
        end
      end
      [last_count, last_value]
    end
  end
end
