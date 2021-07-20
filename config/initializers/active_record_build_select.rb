# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables

# build_select only selects the required fields if the model has ignored_columns.
# This is incompatible with some migrations or background migration specs because
# rails keeps a statement cache in memory. So if a model with ignored_columns in a
# migration is used, the query with select table.col1, table.col2 is stored in the
# statement cache. If a different migration is then run and one of these columns is
# removed in the meantime, the query is invalid.

ActiveRecord::Base.class_eval do
  class_attribute :enumerate_columns_in_select_statements
end

module ActiveRecord
  module QueryMethods
    private

    def build_select(arel)
      if select_values.any?
        arel.project(*arel_columns(select_values.uniq))
      elsif klass.enumerate_columns_in_select_statements
        arel.project(*klass.column_names.map { |field| table[field] })
      else
        arel.project(@klass.arel_table[Arel.star])
      end
    end
  end
end
