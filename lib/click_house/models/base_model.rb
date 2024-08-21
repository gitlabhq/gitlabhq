# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord
module ClickHouse
  module Models
    class BaseModel
      extend Forwardable

      def_delegators :@query_builder, :to_sql

      def initialize(query_builder = ClickHouse::QueryBuilder.new(self.class.table_name))
        @query_builder = query_builder
      end

      def self.table_name
        raise NotImplementedError, "Subclasses must define a `table_name` class method"
      end

      def where(conditions)
        self.class.new(@query_builder.where(conditions))
      end

      def order(field, direction = :asc)
        self.class.new(@query_builder.order(field, direction))
      end

      def limit(count)
        self.class.new(@query_builder.limit(count))
      end

      def offset(count)
        self.class.new(@query_builder.offset(count))
      end

      def group(...)
        self.class.new(@query_builder.group(...))
      end

      def select(...)
        self.class.new(@query_builder.select(...))
      end
    end
  end
end
# rubocop: enable CodeReuse/ActiveRecord
