# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresAutovacuumActivity < SharedModel
      self.table_name = 'postgres_autovacuum_activity'
      self.primary_key = 'table_identifier'

      def self.for_tables(tables)
        Gitlab::Database::LoadBalancing::Session.current.use_primary do
          where('schema = current_schema()').where(table: tables)
        end
      end

      def to_s
        "table #{table_identifier} (started: #{vacuum_start})"
      end
    end
  end
end
