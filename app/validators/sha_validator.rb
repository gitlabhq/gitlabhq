# frozen_string_literal: true

class ShaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || value.match(/\A\h{40}\z/)

    record.errors.add(attribute, 'is not a valid SHA')
  end
end
