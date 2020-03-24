# frozen_string_literal: true

class X509Issuer < ApplicationRecord
  has_many :x509_certificates, inverse_of: 'x509_issuer'

  # rfc 5280 - 4.2.1.1  Authority Key Identifier
  validates :subject_key_identifier, presence: true, format: { with: /\A(\h{2}:){19}\h{2}\z/ }
  # rfc 5280 - 4.1.2.4  Issuer
  validates :subject, presence: true
  # rfc 5280 - 4.2.1.13  CRL Distribution Points
  # cRLDistributionPoints extension using URI:http
  validates :crl_url, presence: true, public_url: true

  def self.safe_create!(attributes)
    create_with(attributes)
      .safe_find_or_create_by!(subject_key_identifier: attributes[:subject_key_identifier])
  end
end
