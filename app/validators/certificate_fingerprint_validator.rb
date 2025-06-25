# frozen_string_literal: true

class CertificateFingerprintValidator < ActiveModel::EachValidator
  FINGERPRINT_PATTERN = /\A([a-zA-Z0-9]{2}[\s\-:]?){16,}\z/
  SHA1_FINGERPRINT_PATTERN = /\A(?:(?:[A-Fa-f0-9]{2}[\s:]){19}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{40})\z/
  SHA256_FINGERPRINT_PATTERN = /\A(?:(?:[A-Fa-f0-9]{2}[\s:]){31}[A-Fa-f0-9]{2}|[A-Fa-f0-9]{64})\z/
  MIN_LENGTH = 40
  MAX_LENGTH = 95

  def validate_each(record, attribute, value)
    # We introduce the new validation logic only for new records and updates that will change the attribute
    # in order to limit the impact on existing invalid records.
    if record.new_record? || record.will_save_change_to_attribute?(attribute)
      validate_sha1_or_sha256_pattern(record, attribute, value)
    else
      validate_length_and_pattern(record, attribute, value)
    end
  end

  private

  def validate_sha1_or_sha256_pattern(record, attribute, value)
    unless within_length_limits?(value) && matches_sha1_or_sha256_pattern?(value)
      record.errors.add(attribute, "must be 40 or 64 hex characters (with optional colons between pairs)")
    end
  end

  def validate_length_and_pattern(record, attribute, value)
    unless value.try(:match, FINGERPRINT_PATTERN)
      record.errors.add(attribute, "must be a hash containing only letters, numbers, spaces, : and -")
    end
  end

  def within_length_limits?(value)
    value.try(:length) && value.length >= MIN_LENGTH && value.length <= MAX_LENGTH
  end

  def matches_sha1_or_sha256_pattern?(value)
    value.try(:match, SHA1_FINGERPRINT_PATTERN) || value.try(:match, SHA256_FINGERPRINT_PATTERN)
  end
end
