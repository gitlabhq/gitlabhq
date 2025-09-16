# frozen_string_literal: true

module Gitlab
  module Database
    class DeleteRelationWithReturning
      DELETE_SQL_TEMPLATE = <<~SQL
        DELETE FROM %{table_name}
        WHERE %{primary_key} IN (%{select_sql})
        %{returning}
      SQL

      def self.execute(...)
        new(...).execute
      end

      def initialize(relation, returning)
        @relation = relation
        @returning = returning
      end

      def execute
        exec_query(delete_sql, 'DELETE').to_a
      end

      private

      attr_reader :relation, :returning

      delegate :connection, :table_name, :primary_key, :column_names, to: :relation, private: true
      delegate :exec_query, :quote_column_name, to: :connection, private: true

      def delete_sql
        format(
          DELETE_SQL_TEMPLATE,
          table_name: table_name,
          primary_key: primary_key,
          select_sql: select_sql,
          returning: returning_clause
        )
      end

      def select_sql
        relation.select(primary_key).to_sql
      end

      def returning_clause
        returning_columns.map { |column| quote_column_name(column) }
                         .join(', ')
                         .then { |columns| "RETURNING #{columns}" }
      end

      def returning_columns
        @returning_columns ||= returning.presence || column_names
      end
    end
  end
end
