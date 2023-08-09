# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord
module ClickHouse
  class QueryBuilder
    attr_reader :table

    def initialize(table_name)
      @table = Arel::Table.new(table_name)
      @manager = Arel::SelectManager.new(Arel::Table.engine)
      @manager.from(@table)
      @manager.project(Arel.star)
    end

    # The `where` method currently does not support range queries like ActiveRecord.
    # For example, using a range (start_date..end_date) will result in incorrect SQL.
    # If you need to query a range, use greater than and less than conditions with Arel.
    #
    # Correct usage:
    #   query.where(query.table[:created_at].lteq(Date.today)).to_sql
    #   "SELECT * FROM \"table\" WHERE \"table\".\"created_at\" <= '2023-08-01'"
    #
    # This also supports array conditions which will result in an IN query.
    #   query.where(entity_id: [1,2,3]).to_sql
    #   "SELECT * FROM \"table\" WHERE \"table\".\"entity_id\" IN (1, 2, 3)"
    #
    # Range support could be considered for future iterations.
    def where(conditions)
      if conditions.is_a?(Arel::Nodes::Node)
        manager.where(conditions)
      else
        conditions.each do |key, value|
          if value.is_a?(Array)
            manager.where(table[key].in(value))
          else
            manager.where(table[key].eq(value))
          end
        end
      end

      self
    end

    def select(*fields)
      manager.projections = []
      fields.each do |field|
        manager.project(table[field])
      end

      self
    end

    def order(field, direction = :asc)
      direction = direction.to_s.downcase
      unless %w[asc desc].include?(direction)
        raise ArgumentError, "Invalid order direction '#{direction}'. Must be :asc or :desc"
      end

      manager.order(table[field].public_send(direction)) # rubocop:disable GitlabSecurity/PublicSend

      self
    end

    def limit(count)
      manager.take(count)
      self
    end

    def offset(count)
      manager.skip(count)
      self
    end

    def to_sql
      manager.to_sql
    end

    private

    attr_reader :manager
  end
end

# rubocop:enable CodeReuse/ActiveRecord
