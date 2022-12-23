# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresForeignKey < SharedModel
      self.primary_key = :oid

      # These values come from the possible confdeltype values in pg_constraint
      enum on_delete_action: {
        restrict: 'r',
        cascade: 'c',
        set_null: 'n',
        set_default: 'd',
        no_action: 'a'
      }

      scope :by_referenced_table_identifier, ->(identifier) do
        raise ArgumentError, "Referenced table name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(referenced_table_identifier: identifier)
      end

      scope :by_constrained_table_identifier, ->(identifier) do
        raise ArgumentError, "Constrained table name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(constrained_table_identifier: identifier)
      end

      scope :not_inherited, -> { where(is_inherited: false) }
    end
  end
end
