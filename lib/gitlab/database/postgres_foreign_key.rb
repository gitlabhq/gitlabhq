# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresForeignKey < SharedModel
      self.primary_key = :oid

      scope :by_referenced_table_identifier, ->(identifier) do
        raise ArgumentError, "Referenced table name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(referenced_table_identifier: identifier)
      end

      scope :by_constrained_table_identifier, ->(identifier) do
        raise ArgumentError, "Constrained table name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(constrained_table_identifier: identifier)
      end
    end
  end
end
