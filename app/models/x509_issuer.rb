# frozen_string_literal: true

class X509Issuer < ApplicationRecord
  has_many :x509_certificates, inverse_of: 'x509_issuer'

  # rfc 5280 - 4.2.1.1  Authority Key Identifier
  validates :subject_key_identifier, presence: true, format: { with: Gitlab::Regex.x509_subject_key_identifier_regex }
  # rfc 5280 - 4.1.2.4  Issuer
  # rfc 5280 - 4.2.1.13  CRL Distribution Points
  # cRLDistributionPoints extension using URI:http
  validates :crl_url, allow_nil: true, public_url: true

  def self.safe_create!(attributes)
    create_with(attributes)
      .safe_find_or_create_by!(subject_key_identifier: attributes[:subject_key_identifier])
  end

  def self.with_crl_url
    where.not(crl_url: nil)
  end
end
