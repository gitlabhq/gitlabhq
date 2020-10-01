# frozen_string_literal: true

# FutureDateValidator

# Validates that a date is in the future.
#
# Example:
#
#   class Member < ActiveRecord::Base
#     validates :expires_at, allow_blank: true, future_date: true
#   end

class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, _('cannot be a date in the past')) if value < Date.current
  end
end
