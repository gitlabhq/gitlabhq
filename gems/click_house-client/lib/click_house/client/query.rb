# frozen_string_literal: true

module ClickHouse
  module Client
    class Query < QueryLike
      SUBQUERY_PLACEHOLDER_REGEX = /{\w+:Subquery}/ # example: {var:Subquery}, special "internal" type for subqueries
      PLACEHOLDER_REGEX = /{\w+:\w+}/ # example: {var:UInt8}
      PLACEHOLDER_NAME_REGEX = /{(\w+):/ # example: {var:UInt8} => var

      def self.build(query)
        return query if query.is_a?(ClickHouse::Client::QueryLike)

        new(raw_query: query)
      end

      def initialize(raw_query:, placeholders: {})
        raise QueryError, 'Empty query string given' if raw_query.blank?

        @raw_query = raw_query
        @placeholders = placeholders || {}
      end

      # List of placeholders to be sent to ClickHouse for replacement.
      # If there are subqueries, merge their placeholders as well.
      def placeholders
        all_placeholders = @placeholders.select { |_, v| !v.is_a?(QueryLike) }
        @placeholders.each_value do |value|
          next unless value.is_a?(QueryLike)

          all_placeholders.merge!(value.placeholders) do |key, a, b|
            raise QueryError, "mismatching values for the '#{key}' placeholder: #{a} vs #{b}"
          end
        end

        all_placeholders
      end

      # Placeholder replacement is handled by ClickHouse, only subquery placeholders
      # will be replaced.
      def to_sql
        raw_query.gsub(SUBQUERY_PLACEHOLDER_REGEX) do |placeholder_in_query|
          value = placeholder_value(placeholder_in_query)

          if value.is_a?(QueryLike)
            value.to_sql
          else
            placeholder_in_query
          end
        end
      end

      def to_redacted_sql(bind_index_manager = BindIndexManager.new)
        raw_query.gsub(PLACEHOLDER_REGEX) do |placeholder_in_query|
          value = placeholder_value(placeholder_in_query)

          if value.is_a?(QueryLike)
            value.to_redacted_sql(bind_index_manager)
          else
            bind_index_manager.next_bind_str
          end
        end
      end

      private

      attr_reader :raw_query

      def placeholder_value(placeholder_in_query)
        placeholder = placeholder_in_query[PLACEHOLDER_NAME_REGEX, 1]
        @placeholders.fetch(placeholder.to_sym)
      end
    end
  end
end
