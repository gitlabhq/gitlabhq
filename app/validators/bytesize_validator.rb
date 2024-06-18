# frozen_string_literal: true

# BytesizeValidator
#
# Custom validator for verifying that bytesize of a field doesn't exceed the specified limit.
# It is different from Rails length validator because it takes .bytesize into account instead of .size/.length
#
# Example:
#
#   class Snippet < ActiveRecord::Base
#     validates :content, bytesize: { maximum: -> { Gitlab::CurrentSettings.snippet_size_limit } }
#   end
#
# Configuration options:
# * <tt>maximum</tt> - Proc that evaluates the bytesize limit that cannot be exceeded
class BytesizeValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    size = value.to_s.bytesize
    max_size = options[:maximum].call

    return if size <= max_size

    error_message = format(_('is too long (%{size}). The maximum size is %{max_size}.'), {
      size: ActiveSupport::NumberHelper.number_to_human_size(size),
      max_size: ActiveSupport::NumberHelper.number_to_human_size(max_size)
    })

    record.errors.add(attr, error_message)
  end
end
