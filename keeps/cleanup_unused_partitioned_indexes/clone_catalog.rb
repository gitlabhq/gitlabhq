# frozen_string_literal: true

require 'gitlab/housekeeper/keep'
require_relative '../helpers/postgres_ai'

module Keeps
  class CleanupUnusedPartitionedIndexes < ::Gitlab::Housekeeper::Keep
    # Reads the production catalog from a postgres.ai thin clone. The clone is
    # the only complete source for partitioned tables: dynamic partitions (and
    # their auto-named child indexes) exist neither in db/structure.sql nor in
    # a locally provisioned database.
    class CloneCatalog
      Error = Class.new(StandardError)

      ParentIndex = Struct.new(:schema, :name, :tablename, :definition, keyword_init: true)

      def self.available?
        Keeps::Helpers::PostgresAi.available?
      end

      def initialize
        raise Error, 'No postgres.ai clone credentials supplied' unless self.class.available?
      end

      # Non-unique, non-partial, non-expression btree parent indexes on
      # partitioned tables, mirroring the phase-1 candidate predicate with the
      # partitioned-parent scope inverted.
      #
      # Every decomposed database physically contains the other databases'
      # tables too, write-locked via the gitlab_schema_prevent_write trigger,
      # and with a stale partition set (partitions only roll forward on the
      # owning cluster). Excluding write-locked tables scopes each run to the
      # tables the connected clone actually owns. PostgreSQL truncates
      # identifiers to 63 bytes, so the stored trigger name is compared
      # against the equally truncated expected name.
      def candidate_parent_indexes
        query = <<~SQL
          SELECT i.schema, i.name, i.tablename, i.definition
          FROM postgres_indexes i
          WHERE i.schema = 'public'
            AND NOT i."unique"
            AND NOT i.exclusion
            AND NOT i.expression
            AND NOT i.partial
            AND i.valid_index
            AND i.type = 'btree'
            AND i.name !~ $1::text
            AND EXISTS (
              SELECT 1 FROM postgres_partitioned_tables p
              WHERE p.schema = i.schema AND p.name = i.tablename
            )
            AND NOT EXISTS (
              SELECT 1 FROM pg_trigger t
              WHERE t.tgrelid = format('%I.%I', i.schema, i.tablename)::regclass
                AND t.tgname = left('gitlab_schema_write_trigger_for_' || i.tablename, 63)
            )
          ORDER BY i.tablename, i.name
        SQL

        temporary_pattern = "#{Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$"

        pg_client.exec_params(query, [temporary_pattern]).map do |row|
          ParentIndex.new(
            schema: row['schema'],
            name: row['name'],
            tablename: row['tablename'],
            definition: row['definition']
          )
        end
      end

      # Real child index names for a parent index, straight from pg_inherits.
      # Detached partitions leave pg_inherits immediately, so they are
      # correctly excluded: a parent-index drop no longer affects them.
      def child_index_names(parent_index_name)
        query = <<~SQL
          SELECT child_idx.relname AS child_index
          FROM pg_class parent_idx
          JOIN pg_namespace n ON n.oid = parent_idx.relnamespace
          JOIN pg_inherits ON pg_inherits.inhparent = parent_idx.oid
          JOIN pg_class child_idx ON child_idx.oid = pg_inherits.inhrelid
          WHERE parent_idx.relname = $1::text
            AND parent_idx.relkind = 'I'
            AND n.nspname = 'public'
          ORDER BY child_idx.relname
        SQL

        pg_client.exec_params(query, [parent_index_name]).field_values('child_index')
      end

      # Ordered key columns of a parent index, for the migration's `down`.
      def index_columns(parent_index_name)
        query = <<~SQL
          SELECT a.attname
          FROM pg_index x
          JOIN pg_class i ON i.oid = x.indexrelid
          JOIN pg_namespace n ON n.oid = i.relnamespace
          JOIN unnest(x.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord) ON true
          JOIN pg_attribute a ON a.attrelid = x.indrelid AND a.attnum = k.attnum
          WHERE i.relname = $1::text
            AND n.nspname = 'public'
            AND k.ord <= x.indnkeyatts
          ORDER BY k.ord
        SQL

        pg_client.exec_params(query, [parent_index_name]).field_values('attname').map(&:to_sym)
      end

      def close
        @postgres_ai&.close
      end

      private

      def pg_client
        postgres_ai.pg_client
      end

      def postgres_ai
        @postgres_ai ||= Keeps::Helpers::PostgresAi.new
      end
    end
  end
end
