# frozen_string_literal: true

module Gitlab
  module Database
    # Backed by the postgres_constraints view
    class PostgresConstraint < SharedModel
      self.primary_key = :oid

      scope :check_constraints, -> { where(constraint_type: 'c') }
      scope :primary_key_constraints, -> { where(constraint_type: 'p') }
      scope :unique_constraints, -> { where(constraint_type: 'u') }
      scope :primary_or_unique_constraints, -> { where(constraint_type: %w[u p]) }

      scope :including_column, ->(column) { where("? = ANY(column_names)", column) }
      scope :not_including_column, ->(column) { where.not("? = ANY(column_names)", column) }

      scope :valid, -> { where(constraint_valid: true) }

      scope :by_table_identifier, ->(identifier) do
        unless Gitlab::Database::FULLY_QUALIFIED_IDENTIFIER.match?(identifier)
          raise ArgumentError, "Table name is not fully qualified with a schema: #{identifier}"
        end

        where(table_identifier: identifier)
      end
    end
  end
end
