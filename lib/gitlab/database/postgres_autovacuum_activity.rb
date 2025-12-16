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

          default_tables, qualified_tables = prepare_table_names(tables)

          execute_in_primary_scope do
            build_query_scope(default_tables, qualified_tables).to_a
          end
        end

        private

        def prepare_table_names(tables)
          qualified_tables, simple_tables = split_qualified_and_simple_tables(tables)

          partitioned_tables = find_partitioned_tables(simple_tables)
          default_tables = simple_tables - partitioned_tables
          partitions = fetch_partitions(partitioned_tables)

          [default_tables, qualified_tables + partitions]
        end

        def split_qualified_and_simple_tables(tables)
          tables
            .partition { |name| fully_qualified?(name) }
            .then { |qualified, simple| [split_qualified_names(qualified), simple.map(&:to_s)] }
        end

        def fully_qualified?(name)
          Gitlab::Database::FULLY_QUALIFIED_IDENTIFIER.match?(name)
        end

        def split_qualified_names(qualified_tables)
          qualified_tables.map { |name| name.split('.') }
        end

        def find_partitioned_tables(tables)
          Gitlab::Database::PostgresPartitionedTable.by_name_in_current_schema(tables).pluck(:name)
        end

        def fetch_partitions(partitioned_tables)
          Gitlab::Database::PostgresPartition.with_parent_tables(partitioned_tables).pluck(:schema, :name)
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
