# frozen_string_literal: true

class KeyRestrictionValidator < ActiveModel::EachValidator
  FORBIDDEN = -1
  ALLOWED = 0

  def self.supported_sizes(type)
    Gitlab::SSHPublicKey.supported_sizes(type)
  end

  def self.supported_key_restrictions(type)
    if Gitlab::FIPS.enabled?
      [*supported_sizes(type), FORBIDDEN]
    else
      [ALLOWED, *supported_sizes(type), FORBIDDEN]
    end
  end

  def validate_each(record, attribute, value)
    unless valid_restriction?(value)
      record.errors.add(attribute, "must be #{supported_sizes_message}")
    end
  end

  private

  def supported_sizes_message
    sizes = []

    sizes << "forbidden" if valid_restriction?(FORBIDDEN)
    sizes << "allowed" if valid_restriction?(ALLOWED)
    sizes += self.class.supported_sizes(options[:type])

    Gitlab::Sentence.to_exclusive_sentence(sizes)
  end

  def valid_restriction?(value)
    choices = self.class.supported_key_restrictions(options[:type])
    choices.include?(value)
  end
end
