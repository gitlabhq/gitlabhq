# frozen_string_literal: true

module Gitlab
  module Database
    # Refuses to drop an index while it is the last one supporting a foreign
    # key, since FK checks on the referenced table would then scan the table.
    class ForeignKeyIndexSupport
      def initialize(connection)
        @connection = connection
      end

      def assert_index_not_last_supporting_foreign_key!(table_name, index)
        return unless index

        dropped_index_columns = foreign_key_supporting_columns(index)
        return unless dropped_index_columns

        remaining = connection.indexes(table_name)
          .reject { |other| other.name == index.name }
          .filter_map { |other| foreign_key_supporting_columns(other) }
        remaining << Array.wrap(connection.primary_key(table_name))

        connection.foreign_keys(table_name).each do |foreign_key|
          column_sets = required_column_sets(foreign_key)
          next unless column_sets.any? { |columns| covers_columns?(dropped_index_columns, columns) }

          next if remaining.any? do |index_columns|
            column_sets.any? do |columns|
              covers_columns?(index_columns, columns)
            end
          end

          raise ArgumentError, "Index #{index.name} is the only index supporting the foreign key " \
            "#{foreign_key.name} on #{table_name} (#{Array.wrap(foreign_key.column).join(', ')}). Dropping it " \
            "would make deletes on #{foreign_key.to_table} sequentially scan #{table_name}. Remove or replace " \
            "the foreign key first, or create the replacement index before removing this one."
        end
      end

      private

      attr_reader :connection

      # A CI partition holds rows for a single partition_id, so an index on the
      # remaining FK columns is also sufficient, as in spec/db/schema_spec.rb.
      def required_column_sets(foreign_key)
        fk_columns = Array.wrap(foreign_key.column).map(&:to_s)

        column_sets = [fk_columns]
        column_sets << fk_columns.drop(1) if ci_partitioned_foreign_key?(foreign_key)
        column_sets
      end

      # An index supports a foreign key when the FK columns are covered by the
      # index's leading columns, mirroring the contract in spec/db/schema_spec.rb.
      def foreign_key_supporting_columns(index)
        return unless index.using.nil? || index.using == :btree

        # Expression indexes arrive as a String, e.g. "namespace_id, lower(name)";
        # their plain leading columns still support a foreign key.
        columns = index.columns
        columns = columns.split(',').map(&:strip) if columns.is_a?(String)
        return unless index.where.nil? || index.where == "(#{columns.first} IS NOT NULL)"
        # An invalid index (e.g. an aborted concurrent build) supports nothing.
        return unless index.valid?

        columns
      end

      def covers_columns?(index_columns, fk_columns)
        (fk_columns - index_columns.first(fk_columns.length)).empty?
      end

      def ci_partitioned_foreign_key?(foreign_key)
        target = foreign_key.to_table.to_s.split('.').last

        Gitlab::Database::GitlabSchema.table_schema(target) == :gitlab_ci &&
          Array.wrap(foreign_key.column).many? &&
          foreign_key.column.first.to_s.end_with?('partition_id')
      end
    end
  end
end
