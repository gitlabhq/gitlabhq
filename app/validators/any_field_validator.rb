# frozen_string_literal: true

# AnyFieldValidator
#
# Custom validator that checks if any of the provided
# fields are present to ensure creation of a non-empty
# record
#
# Example:
#
#   class MyModel < ApplicationRecord
#     validates_with AnyFieldValidator, fields: %w[type name url]
#   end
class AnyFieldValidator < ActiveModel::Validator
  def initialize(*args)
    super

    if options[:fields].blank?
      raise 'Provide the fields options'
    end
  end

  def validate(record)
    return unless one_of_required_fields.all? { |field| record[field].blank? }

    record.errors.add(:base, _("At least one field of %{one_of_required_fields} must be present") %
      { one_of_required_fields: one_of_required_fields })
  end

  private

  def one_of_required_fields
    options[:fields]
  end
end
