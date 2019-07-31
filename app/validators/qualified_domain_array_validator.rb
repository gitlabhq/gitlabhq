# frozen_string_literal: true

# QualifiedDomainArrayValidator
#
# Custom validator for URL hosts/'qualified domains' (FQDNs, ex: gitlab.com, sub.example.com).
# This does not check if the domain actually exists. It only checks if it is a
# valid domain string.
#
# Example:
#
#   class ApplicationSetting < ApplicationRecord
#     validates :outbound_local_requests_whitelist, qualified_domain_array: true
#   end
#
class QualifiedDomainArrayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    validate_value_present(record, attribute, value)
    validate_host_length(record, attribute, value)
    validate_idna_encoding(record, attribute, value)
    validate_sanitization(record, attribute, value)
  end

  private

  def validate_value_present(record, attribute, value)
    return unless value.nil?

    record.errors.add(attribute, _('entries cannot be nil'))
  end

  def validate_host_length(record, attribute, value)
    return unless value&.any? { |entry| entry.size > 255 }

    record.errors.add(attribute, _('entries cannot be larger than 255 characters'))
  end

  def validate_idna_encoding(record, attribute, value)
    return if value&.all?(&:ascii_only?)

    record.errors.add(attribute, _('unicode domains should use IDNA encoding'))
  end

  def validate_sanitization(record, attribute, value)
    sanitizer = Rails::Html::FullSanitizer.new
    return unless value&.any? { |str| sanitizer.sanitize(str) != str }

    record.errors.add(attribute, _('entries cannot contain HTML tags'))
  end
end
