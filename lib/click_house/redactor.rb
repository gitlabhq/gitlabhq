# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord
module ClickHouse
  module Redactor
    # Redacts the SQL query represented by the query builder.
    #
    # @param query_builder [::ClickHouse::Querybuilder] The query builder object to be redacted.
    # @return [String] The redacted SQL query as a string.
    # @raise [ArgumentError] when the condition in the query is of an unsupported type.
    #
    # Example:
    #   query_builder = ClickHouse::QueryBuilder.new('users').where(name: 'John Doe')
    #   redacted_query = ClickHouse::Redactor.redact(query_builder)
    #   # The redacted_query will contain the SQL query with values replaced by placeholders.
    #   output: "SELECT * FROM \"users\" WHERE \"users\".\"name\" = $1"
    def self.redact(query_builder, bind_manager = ClickHouse::Client::BindIndexManager.new)
      cloned_query_builder = query_builder.clone

      cloned_query_builder.conditions = cloned_query_builder.conditions.map do |condition|
        redact_condition(condition, bind_manager)
      end

      cloned_query_builder.manager.constraints.clear
      cloned_query_builder.conditions.each do |condition|
        cloned_query_builder.manager.where(condition)
      end

      cloned_query_builder.manager.to_sql
    end

    def self.redact_condition(condition, bind_manager)
      case condition
      when Arel::Nodes::In
        condition.left.in(Array.new(condition.right.size) { Arel.sql(bind_manager.next_bind_str) })
      when Arel::Nodes::Equality
        condition.left.eq(Arel.sql(bind_manager.next_bind_str))
      when Arel::Nodes::LessThan
        condition.left.lt(Arel.sql(bind_manager.next_bind_str))
      when Arel::Nodes::LessThanOrEqual
        condition.left.lteq(Arel.sql(bind_manager.next_bind_str))
      when Arel::Nodes::GreaterThan
        condition.left.gt(Arel.sql(bind_manager.next_bind_str))
      when Arel::Nodes::GreaterThanOrEqual
        condition.left.gteq(Arel.sql(bind_manager.next_bind_str))
      else
        raise ArgumentError, "Unsupported Arel node type for Redactor: #{condition.class}"
      end
    end
  end
end
# rubocop:enable CodeReuse/ActiveRecord
