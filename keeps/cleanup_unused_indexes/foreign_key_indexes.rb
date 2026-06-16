# frozen_string_literal: true

require 'gitlab/housekeeper/keep'

module Keeps
  class CleanupUnusedIndexes < ::Gitlab::Housekeeper::Keep
    # Schema-qualified identifiers of indexes that support an FK lookup,
    # gathered from hard FKs (PostgresForeignKey) and LooseForeignKeys.
    #
    # An index "supports" an FK when its first column matches one of the FK's
    # referencing columns. Composite FKs deliberately over-match: better to
    # skip a removable index than to drop one a cascade still depends on.
    class ForeignKeyIndexes
      INDEX_SCHEMA = 'public'

      def initialize(connection)
        @connection = connection
      end

      def include?(identifier)
        identifiers.include?(identifier)
      end

      def identifiers
        @identifiers ||= compute_identifiers
      end

      private

      attr_reader :connection

      def compute_identifiers
        fk_columns_by_table.each_with_object(Set.new) do |(table, fk_columns), set|
          connection.indexes(table).each do |idx|
            next unless fk_columns.include?(idx.columns.first.to_s)

            set << "#{INDEX_SCHEMA}.#{idx.name}"
          end
        rescue ActiveRecord::StatementInvalid => e
          warn "[ForeignKeyIndexes] could not inspect #{table}: #{e.class}: #{e.message}"
          next
        end
      end

      def fk_columns_by_table
        (hard_fk_pairs + loose_fk_pairs)
          .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |(table, column), hash|
            hash[table] << column.to_s
          end
      end

      # rubocop:disable CodeReuse/ActiveRecord -- PostgresForeignKey is a metadata model with no domain layer.
      def hard_fk_pairs
        ::Gitlab::Database::PostgresForeignKey
          .not_inherited
          .pluck(:constrained_table_name, :constrained_columns)
          .flat_map { |table, columns| Array(columns).map { |column| [table, column] } }
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def loose_fk_pairs
        ::Gitlab::Database::LooseForeignKeys.definitions.map { |d| [d.from_table, d.column.to_s] }
      end
    end
  end
end
