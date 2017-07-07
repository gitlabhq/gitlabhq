module EachBatch
  extend ActiveSupport::Concern

  module ClassMethods
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
    #       relation.update_all(updated_at: Time.now)
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
    #     User Load (0.7ms)  SELECT  "users"."id" FROM "users" WHERE ("users"."id" >= 41654)  ORDER BY "users"."id" ASC LIMIT 1 OFFSET 1000
    #       (0.7ms)  SELECT COUNT(*) FROM "users" WHERE ("users"."id" >= 41654) AND ("users"."id" < 42687)
    #
    # of - The number of rows to retrieve per batch.
    # column - The column to use for ordering the batches.
    def each_batch(of: 1000, column: primary_key)
      unless column
        raise ArgumentError,
          'the column: argument must be set to a column name to use for ordering rows'
      end

      start = except(:select)
        .select(column)
        .reorder(column => :asc)
        .take

      return unless start

      start_id = start[column]
      arel_table = self.arel_table

      1.step do |index|
        stop = except(:select)
          .select(column)
          .where(arel_table[column].gteq(start_id))
          .reorder(column => :asc)
          .offset(of)
          .limit(1)
          .take

        relation = where(arel_table[column].gteq(start_id))

        if stop
          stop_id = stop[column]
          start_id = stop_id
          relation = relation.where(arel_table[column].lt(stop_id))
        end

        # Any ORDER BYs are useless for this relation and can lead to less
        # efficient UPDATE queries, hence we get rid of it.
        yield relation.except(:order), index

        break unless stop
      end
    end
  end
end
