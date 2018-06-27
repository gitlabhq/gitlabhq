class CertificateFingerprintValidator < ActiveModel::EachValidator
  FINGERPRINT_PATTERN = /\A([a-zA-Z0-9]{2}[\s\-:]?){16,}\z/.freeze

  def validate_each(record, attribute, value)
    unless value.try(:match, FINGERPRINT_PATTERN)
      record.errors.add(attribute, "must be a hash containing only letters, numbers, spaces, : and -")
    end
  end
end
