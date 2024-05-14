# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresPartition < SharedModel
      self.primary_key = :identifier

      belongs_to :postgres_partitioned_table, foreign_key: 'parent_identifier', primary_key: 'identifier'

      # identifier includes the partition schema.
      # For example 'gitlab_partitions_static.events_03', or 'gitlab_partitions_dynamic.logs_03'
      scope :for_identifier, ->(identifier) do
        unless Gitlab::Database::FULLY_QUALIFIED_IDENTIFIER.match?(identifier)
          raise ArgumentError, "Partition name is not fully qualified with a schema: #{identifier}"
        end

        where(primary_key => identifier)
      end

      scope :by_identifier, ->(identifier) do
        for_identifier(identifier).first!
      end

      scope :for_parent_table, ->(parent_table) do
        if Database::FULLY_QUALIFIED_IDENTIFIER.match?(parent_table)
          where(parent_identifier: parent_table).order(:name)
        else
          where("parent_identifier = concat(current_schema(), '.', ?)", parent_table).order(:name)
        end
      end

      scope :with_parent_tables, ->(parent_tables) do
        parent_identifiers = parent_tables.map { |name| "#{connection.current_schema}.#{name}" }

        where(parent_identifier: parent_identifiers).order(:name)
      end

      scope :with_list_constraint, ->(condition) do
        where(sanitize_sql_for_conditions(['condition LIKE ?', "FOR VALUES IN (%'#{condition.to_i}'%)"]))
      end

      scope :above_threshold, ->(threshold) do
        where('pg_table_size(identifier) > ?', threshold)
      end

      def self.partition_exists?(table_name)
        where("identifier = concat(current_schema(), '.', ?)", table_name).exists?
      end

      def self.legacy_partition_exists?(table_name)
        result = connection.select_value(<<~SQL)
          SELECT true FROM pg_class
          WHERE relname = '#{table_name}'
          AND relispartition = true;
        SQL

        !!result
      end

      def to_s
        name
      end
    end
  end
end
