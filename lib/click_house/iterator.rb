# frozen_string_literal: true

module ClickHouse
  # This class implements a batch iterator which can be used for ClickHouse database tables.
  # The batching logic uses fixed id ranges because that's the only way to efficiently batch
  # over the data. This is similar to the implementation of the Gitlab::Database::BatchCount
  # utility class.
  #
  # Usage:
  #
  # connection = ClickHouse::Connection.new(:main)
  # builder = ClickHouse::QueryBuilder.new('event_authors')
  # iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection)
  # iterator.each_batch(column: :author_id, of: 100000) do |scope|
  #   puts scope.to_sql
  #   puts ClickHouse::Client.select(scope.to_sql, :main)
  # end
  #
  # If your database table structure is optimized for a specific filter, you could scan smaller
  # part of the table by adding more condition to the query builder. Example:
  #
  # builder = ClickHouse::QueryBuilder.new('event_authors').where(type: 'some_type')
  class Iterator
    # rubocop: disable CodeReuse/ActiveRecord -- this is a ClickHouse query builder class usin Arel
    def initialize(query_builder:, connection:, min_value: nil)
      @query_builder = query_builder
      @connection = connection
      @min_value = min_value
    end

    def each_batch(column: :id, of: 10_000)
      min_max_query = query_builder.select(
        table[column].minimum.as('min'),
        table[column].maximum.as('max')
      )

      row = connection.select(min_max_query.to_sql).first
      return if row.nil?

      min = min_value || row['min']
      max = row['max']
      return if max == 0

      loop do
        break if min > max

        upper_bound = (min + of) - 1
        yield query_builder
          .where(table[column].gteq(min))
          .where(table[column].lteq(upper_bound)), min, upper_bound

        min += of
      end
    end

    private

    delegate :table, to: :query_builder

    attr_reader :query_builder, :connection, :min_value
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
