# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresAutovacuumActivity < SharedModel
      self.table_name = 'postgres_autovacuum_activity'
      self.primary_key = 'table_identifier'

      scope :wraparound_prevention, -> { where(wraparound_prevention: true) }

      class << self
        def for_tables(tables)
          return [] if tables.empty?

          partitioned_tables, regular_tables = partition_tables(tables)
          partitions = PostgresPartition.with_parent_tables(partitioned_tables).pluck(:schema, :name)

          execute_in_primary_scope do
            build_query_scope(regular_tables, partitions).to_a
          end
        end

        private

        def partition_tables(tables)
          tables.partition { |table_name| partitioned_table?(table_name) }
        end

        def partitioned_table?(table_name)
          Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(table_name).present?
        end

        def execute_in_primary_scope(&block)
          Gitlab::Database::LoadBalancing::SessionMap
            .current(load_balancer)
            .use_primary(&block)
        end

        def build_query_scope(regular_tables, partitions)
          base_scope = where('schema = current_schema()').where(table: regular_tables)

          partitions.reduce(base_scope) do |accumulated_scope, (schema, name)|
            accumulated_scope.or(where(schema: schema, table: name))
          end
        end
      end

      def to_s
        "table #{table_identifier} (started: #{vacuum_start})"
      end
    end
  end
end
