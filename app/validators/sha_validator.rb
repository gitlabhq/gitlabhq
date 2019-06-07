# frozen_string_literal: true

class ShaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || Commit.valid_hash?(value)

    record.errors.add(attribute, 'is not a valid SHA')
  end
end
