# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresAutovacuumActivity < SharedModel
      self.table_name = 'postgres_autovacuum_activity'
      self.primary_key = 'table_identifier'

      scope :wraparound_prevention, -> { where(wraparound_prevention: true) }

      def self.for_tables(tables)
        Gitlab::Database::LoadBalancing::SessionMap
          .current(load_balancer)
          .use_primary do
          # calling `.to_a` here to execute the query in the primary's scope
          # and to avoid having the scope chained and re-executed
          #
          where('schema = current_schema()').where(table: tables).to_a
        end
      end

      def to_s
        "table #{table_identifier} (started: #{vacuum_start})"
      end
    end
  end
end
