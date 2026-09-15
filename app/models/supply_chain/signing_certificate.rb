# frozen_string_literal: true

module SupplyChain
  class SigningCertificate < ::ApplicationRecord
    CERTIFICATE_MAX_LENGTH = 3072
    # Above the usual guideline for encrypted attributes because PEM private
    # keys are inherently large (RSA-2048 is ~1.7KB, RSA-8192 is ~6.4KB).
    PRIVATE_KEY_MAX_LENGTH = 10.kilobytes

    self.table_name = 'supply_chain_signing_certificates'

    belongs_to :project, optional: false

    encrypts :private_key

    prevent_from_serialization :private_key

    validates :private_key, presence: true, length: { maximum: PRIVATE_KEY_MAX_LENGTH }
    validates :private_key, certificate_key: true, allow_blank: true
    validates :certificate, presence: true, length: { maximum: CERTIFICATE_MAX_LENGTH }
    validates :certificate, certificate: true, allow_blank: true
    validates :expires_at, presence: true
    validates :expires_at, future_date: true, on: :create
    validates :active, inclusion: { in: [true, false] }
    validates :active, uniqueness: { scope: :project_id }, if: :active
    validate :validate_matching_key, if: -> { certificate.present? && private_key.present? }

    def certificate=(value)
      super

      self.expires_at = x509&.not_after
    end

    private

    def validate_matching_key
      return if x509.nil? || pkey.nil?

      errors.add(:private_key, _("doesn't match the certificate")) unless x509.check_private_key(pkey)
    end

    def x509
      return if certificate.blank?

      OpenSSL::X509::Certificate.new(certificate)
    rescue OpenSSL::X509::CertificateError
      nil
    end

    def pkey
      return if private_key.blank?

      OpenSSL::PKey.read(private_key)
    rescue OpenSSL::PKey::PKeyError, OpenSSL::Cipher::CipherError
      nil
    end
  end
end

SupplyChain::SigningCertificate.prepend_mod
