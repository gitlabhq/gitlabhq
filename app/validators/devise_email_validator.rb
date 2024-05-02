# frozen_string_literal: true

# DeviseEmailValidator
#
# Custom validator for email formats. It asserts that there are no
# @ symbols or whitespaces in either the localpart or the domain, and that
# there is a single @ symbol separating the localpart and the domain.
#
# The available options are:
# - regexp: Email regular expression used to validate email formats as instance of Regexp class.
#           If provided value has different type then a new Rexexp class instance is created using the value.
#           Default: +Devise.email_regexp+
#
# Example:
#   class User < ActiveRecord::Base
#     validates :personal_email, devise_email: true
#
#     validates :public_email, devise_email: { regexp: Devise.email_regexp }
#   end
class DeviseEmailValidator < ActiveModel::EachValidator
  DEFAULT_OPTIONS = {
    regexp: Devise.email_regexp,
    encoded_word_regexp: %r{=[?].*[?]=}
  }.freeze

  def initialize(options)
    options.reverse_merge!(DEFAULT_OPTIONS)

    raise ArgumentError, "Expected 'regexp' argument of type class Regexp" unless options[:regexp].is_a?(Regexp)

    super(options)
  end

  def validate_each(record, attribute, value)
    return if record.errors.include?(attribute)

    record.errors.add(attribute, :invalid) unless valid_email?(value)
  end

  private

  def valid_email?(value)
    options[:regexp].match?(value) && !options[:encoded_word_regexp].match?(value)
  end
end
