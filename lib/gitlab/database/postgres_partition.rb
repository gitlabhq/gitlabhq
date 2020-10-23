# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresPartition < ActiveRecord::Base
      self.primary_key = :identifier

      belongs_to :postgres_partitioned_table, foreign_key: 'parent_identifier', primary_key: 'identifier'

      scope :by_identifier, ->(identifier) do
        raise ArgumentError, "Partition name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        find(identifier)
      end

      scope :for_parent_table, ->(name) { where("parent_identifier = concat(current_schema(), '.', ?)", name).order(:name) }

      def to_s
        name
      end
    end
  end
end
