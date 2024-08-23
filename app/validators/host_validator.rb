# frozen_string_literal: true

# HostValidator
#
# Custom validator for Hosts.
#
# This is similar to an URI validator, but will make sure no schema or
# path is present, only the domain part.
#
class HostValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass,Gitlab/BoundedContexts -- This is a globally shareable validator, but it's unclear what namespace it should belong in
  def validate_each(record, attribute, value)
    return if valid_host?(value)

    record.errors.add(attribute, 'must be a valid hostname!')
  end

  private

  def valid_host?(value)
    URI.parse("http://#{value}").host == value
  rescue URI::InvalidURIError
    false
  end
end
