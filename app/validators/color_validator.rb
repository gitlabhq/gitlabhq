# frozen_string_literal: true

# ColorValidator
#
# Custom validator for web color codes. It requires the leading hash symbol and
# will accept RGB triplet or hexadecimal formats.
#
# Example:
#
#   class User < ActiveRecord::Base
#     validates :background_color, allow_blank: true, color: true
#   end
#
class ColorValidator < ActiveModel::EachValidator
  PATTERN = /\A\#(?:[0-9A-Fa-f]{3}){1,2}\Z/.freeze

  def validate_each(record, attribute, value)
    unless value =~ PATTERN
      record.errors.add(attribute, "must be a valid color code")
    end
  end
end
