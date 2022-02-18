# frozen_string_literal: true

# X509CertificateCredentialsValidator
#
# Custom validator to check if certificate-attribute was signed using the
# private key stored in an attrebute.
#
# This can be used as an `ActiveModel::Validator` as follows:
#
#   validates_with X509CertificateCredentialsValidator,
#                  certificate: :client_certificate,
#                  pkey: :decrypted_private_key,
#                  pass: :decrypted_passphrase
#
#
# Required attributes:
# - certificate: The name of the accessor that returns the certificate to check
# - pkey: The name of the accessor that returns the private key
# Optional:
# - pass: The name of the accessor that returns the passphrase to decrypt the
#         private key
class X509CertificateCredentialsValidator < ActiveModel::Validator
  def initialize(*args)
    super

    # We can't validate if we don't have a private key or certificate attributes
    # in which case this validator is useless.
    if options[:pkey].nil? || options[:certificate].nil?
      raise 'Provide at least `certificate` and `pkey` attribute names'
    end
  end

  def validate(record)
    unless certificate = read_certificate(record)
      record.errors.add(options[:certificate], _('is not a valid X509 certificate.'))
    end

    unless private_key = read_private_key(record)
      record.errors.add(options[:pkey], _('could not read private key, is the passphrase correct?'))
    end

    return if private_key.nil? || certificate.nil?

    unless certificate.check_private_key(private_key)
      record.errors.add(options[:pkey], _('private key does not match certificate.'))
    end
  end

  private

  def read_private_key(record)
    OpenSSL::PKey.read(pkey(record).to_s, pass(record).to_s)
  rescue OpenSSL::PKey::PKeyError, ArgumentError
    # When the primary key could not be read, an ArgumentError is raised.
    # This hapens when the passed key is not valid or the passphrase is incorrect
    nil
  end

  def read_certificate(record)
    OpenSSL::X509::Certificate.new(certificate(record).to_s)
  rescue OpenSSL::X509::CertificateError
    nil
  end

  # rubocop:disable GitlabSecurity/PublicSend
  #
  # Allowing `#public_send` here because we don't want the validator to really
  # care about the names of the attributes or where they come from.
  #
  # The credentials are mostly stored encrypted so we need to go through the
  # accessors to get the values, `read_attribute` bypasses those.
  def certificate(record)
    record.public_send(options[:certificate])
  end

  def pkey(record)
    record.public_send(options[:pkey])
  end

  def pass(record)
    return unless options[:pass]

    record.public_send(options[:pass])
  end
  # rubocop:enable GitlabSecurity/PublicSend
end
