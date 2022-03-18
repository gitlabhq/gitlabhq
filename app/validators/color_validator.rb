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
  def validate_each(record, attribute, value)
    case value
    when NilClass        then return
    when ::Gitlab::Color then return if value.valid?
    when ::String        then return if ::Gitlab::Color.new(value).valid?
    end

    record.errors.add(attribute, "must be a valid color code")
  end
end
