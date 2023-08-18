# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresPartitionedTable < SharedModel
      DYNAMIC_PARTITION_STRATEGIES = %w[range list].freeze

      self.primary_key = :identifier

      has_many :postgres_partitions, foreign_key: 'parent_identifier', primary_key: 'identifier'

      scope :by_identifier, ->(identifier) do
        unless Gitlab::Database::FULLY_QUALIFIED_IDENTIFIER.match?(identifier)
          raise ArgumentError, "Table name is not fully qualified with a schema: #{identifier}"
        end

        find(identifier)
      end

      def self.find_by_name_in_current_schema(name)
        find_by("identifier = concat(current_schema(), '.', ?)", name)
      end

      def self.each_partition(table_name, &block)
        find_by_name_in_current_schema(table_name)
        .postgres_partitions
        .order(:name)
        .each(&block)
      end

      def dynamic?
        DYNAMIC_PARTITION_STRATEGIES.include?(strategy)
      end

      def static?
        !dynamic?
      end

      def to_s
        name
      end
    end
  end
end
