# frozen_string_literal: true

# == SafelyChangeColumnDefault concern.
#
# Contains functionality that allows safely changing a column default without downtime.
# Without this concern, Rails can mutate the old default value to the new default value if the old default is explicitly
# specified.
#
# Usage:
#
#   class SomeModel < ApplicationRecord
#     include SafelyChangeColumnDefault
#
#     columns_changing_default :value
#   end
#
#   # Assume a default of 100 for value
#   SomeModel.create!(value: 100) # INSERT INTO some_model (value) VALUES (100)
#   change_column_default('some_model', 'value', from: 100, to: 101)
#   SomeModel.create!(value: 100) # INSERT INTO some_model (value) VALUES (100)
#   # Without this concern, would be INSERT INTO some_model (value) DEFAULT VALUES and would insert 101.
module SafelyChangeColumnDefault
  extend ActiveSupport::Concern

  class_methods do
    # Indicate that one or more columns will have their database default change.
    #
    # By indicating those columns here, this helper prevents a case where explicitly writing the old database default
    # will be mutated to the new database default.
    def columns_changing_default(*columns)
      self.columns_with_changing_default = columns.map(&:to_s)
    end
  end

  included do
    class_attribute :columns_with_changing_default, default: []

    before_create do
      columns_with_changing_default.to_a.each do |attr_name|
        attr = @attributes[attr_name]

        attribute_will_change!(attr_name) if !attr.changed? && attr.came_from_user?
      end
    end
  end
end
