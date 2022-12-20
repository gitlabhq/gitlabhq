# frozen_string_literal: true

class Iso8601DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    Date.iso8601(record.read_attribute_before_type_cast(attribute).to_s)
  rescue ArgumentError, TypeError
    record.errors.add(attribute, _('must be in ISO 8601 format'))
  end
end
