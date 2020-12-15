# frozen_string_literal: true

# Concern for querying columns with specific case sensitivity handling.
module CaseSensitivity
  extend ActiveSupport::Concern

  class_methods do
    # Queries the given columns regardless of the casing used.
    #
    # Unlike other ActiveRecord methods this method only operates on a Hash.
    def iwhere(params)
      criteria = self

      params.each do |column, value|
        column = arel_table[column] unless column.is_a?(Arel::Attribute)

        criteria = case value
                   when Array
                     criteria.where(value_in(column, value))
                   else
                     criteria.where(value_equal(column, value))
                   end
      end

      criteria
    end

    private

    def value_equal(column, value)
      lower_value = lower_value(value)

      lower_column(column).eq(lower_value).to_sql
    end

    def value_in(column, values)
      lower_values = values.map do |value|
        lower_value(value)
      end

      lower_column(column).in(lower_values).to_sql
    end

    def lower_value(value)
      Arel::Nodes::NamedFunction.new('LOWER', [Arel::Nodes.build_quoted(value)])
    end

    def lower_column(column)
      column.lower
    end
  end
end
