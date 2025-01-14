# frozen_string_literal: true

class X509Certificate < ApplicationRecord
  include X509SerialNumberAttribute
  include AfterCommitQueue

  x509_serial_number_attribute :serial_number

  enum certificate_status: {
    good: 0,
    revoked: 1
  }

  belongs_to :x509_issuer, class_name: 'X509Issuer', foreign_key: 'x509_issuer_id', optional: false

  has_many :x509_commit_signatures, class_name: 'CommitSignatures::X509CommitSignature', inverse_of: 'x509_certificate'

  # rfc 5280 - 4.2.1.2  Subject Key Identifier
  validates :subject_key_identifier, presence: true, format: { with: Gitlab::Regex.x509_subject_key_identifier_regex }
  # rfc 5280 - 4.1.2.6  Subject (subjectAltName contains the email address)
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # rfc 5280 - 4.1.2.2  Serial number
  validates :serial_number, presence: true, numericality: { only_integer: true }

  validates :x509_issuer_id, presence: true

  scope :by_x509_issuer, ->(issuer) { where(x509_issuer_id: issuer.id) }

  after_commit :mark_commit_signatures_unverified

  def self.safe_create!(attributes)
    create_with(attributes)
      .safe_find_or_create_by!(subject_key_identifier: attributes[:subject_key_identifier])
  end

  def self.serial_numbers(issuer)
    by_x509_issuer(issuer).pluck(:serial_number)
  end

  def all_emails
    [email, emails].flatten.compact.uniq
  end

  def mark_commit_signatures_unverified
    X509CertificateRevokeWorker.perform_async(self.id) if revoked?
  end
end
