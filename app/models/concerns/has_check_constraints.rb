# frozen_string_literal: true

module HasCheckConstraints
  extend ActiveSupport::Concern

  NOT_NULL_CHECK_PATTERN = /IS NOT NULL/i

  class_methods do
    def not_null_check?(column_name)
      constraints.any? do |constraint|
        constraint.constraint_valid &&
          constraint.column_names.include?(column_name) &&
          NOT_NULL_CHECK_PATTERN.match(constraint.definition)
      end
    end

    def clear_constraints_cache!
      @constraints = nil
    end

    private

    def constraints
      @constraints ||= Gitlab::Database::PostgresConstraint.check_constraints
                                                           .by_table_identifier(fully_qualified_table_name)
    end

    def fully_qualified_table_name
      "#{connection.current_schema}.#{table_name}"
    end
  end
end
