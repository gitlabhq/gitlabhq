# frozen_string_literal: true

# DeviseEmailValidator
#
# Custom validator for email formats. It asserts that there are no
# @ symbols or whitespaces in either the localpart or the domain, and that
# there is a single @ symbol separating the localpart and the domain.
#
# Example:
#   class User < ActiveRecord::Base
#     validates :personal_email, devise_email: true
#   end
class DeviseEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.errors.include?(attribute)

    record.errors.add(attribute, :invalid) unless valid_email?(value)
  end

  private

  def valid_email?(value)
    Gitlab::Utils::Email.valid_email?(value)
  end
end
