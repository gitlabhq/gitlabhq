# frozen_string_literal: true

module Gitlab
  module Database
    class TablesSortedByForeignKeys
      include TSort

      def initialize(connection, tables)
        @connection = connection
        @tables = tables
      end

      def execute
        strongly_connected_components
      end

      private

      def tsort_each_node(&block)
        tables_dependencies.each_key(&block)
      end

      def tsort_each_child(node, &block)
        tables_dependencies[node].each(&block)
      end

      # it maps the tables to the tables that depend on it
      def tables_dependencies
        @tables.index_with do |table_name|
          all_foreign_keys[table_name]
        end
      end

      def all_foreign_keys
        @all_foreign_keys ||= @tables.each_with_object(Hash.new { |h, k| h[k] = [] }) do |table, hash|
          foreign_keys_for(table).each { |fk| record_dependency(hash, fk, table) }

          # FKs held by an attached partition live on the partition, not the
          # partitioned parent, and the partition is not listed in @tables (its
          # rows are cleared by TRUNCATE cascading from the parent). Attribute
          # those FKs to the parent so a table the partition references is
          # ordered before the parent's batch--otherwise PostgreSQL raises a
          # feature-not-supported error when the parent's TRUNCATE cascade hits
          # the still-referenced partition.
          attached_partition_foreign_keys_for(table).each { |fk| record_dependency(hash, fk, table) }
        end
      end

      def record_dependency(hash, fk, table)
        hash[fk.referenced_table_name] << table

        # When the FK targets an attached partition, also record the
        # dependency against the partitioned parent. TRUNCATE on the parent
        # cascades to every partition, so any referencing table must be
        # truncated before the parent's batch--otherwise PostgreSQL raises
        # a feature-not-supported error on the implicit partition truncate.
        parent = partition_parents[fk.referenced_table_name]
        hash[parent] << table if parent
      end

      def partition_parents
        partition_metadata[:parents]
      end

      def partitions_by_parent
        partition_metadata[:children]
      end

      # Loads every partition once and derives two maps: partition name to its
      # parent's unqualified name, and parent's unqualified name to its
      # partition names. Both callers reuse this single query instead of
      # issuing a per-parent-table partition lookup.
      def partition_metadata
        @partition_metadata ||= Gitlab::Database::SharedModel.using_connection(@connection) do
          empty_metadata = { parents: {}, children: Hash.new { |h, k| h[k] = [] } }

          # Load all partitions in a single query on purpose; find_each would
          # split this into batches, defeating the point of caching it once.
          Gitlab::Database::PostgresPartition.all.to_a.each_with_object(empty_metadata) do |partition, metadata|
            parent = partition.parent_identifier.split('.', 2).last

            metadata[:parents][partition.name] = parent
            metadata[:children][parent] << partition.name
          end
        end
      end

      def foreign_keys_for(table)
        # Detached partitions like gitlab_partitions_dynamic._test_gitlab_partition_20220101
        # store their foreign keys in the public schema.
        #
        # See spec/lib/gitlab/database/tables_sorted_by_foreign_keys_spec.rb
        # for an example
        table = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils.extract_schema_qualified_name(table)

        Gitlab::Database::SharedModel.using_connection(@connection) do
          Gitlab::Database::PostgresForeignKey.by_constrained_table_name_or_identifier(table.identifier).load
        end
      end

      # Foreign keys constrained on the attached partitions of a partitioned
      # +table+. Returns [] for non-partitioned tables. Reuses the partitions
      # already loaded in partition_metadata and issues one batched FK query,
      # rather than a partition lookup per table and an FK query per partition.
      def attached_partition_foreign_keys_for(table)
        name = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils.extract_schema_qualified_name(table).identifier
        partition_names = partitions_by_parent[name]
        return [] if partition_names.empty?

        Gitlab::Database::SharedModel.using_connection(@connection) do
          Gitlab::Database::PostgresForeignKey.by_constrained_table_name(partition_names).to_a
        end
      end
    end
  end
end
