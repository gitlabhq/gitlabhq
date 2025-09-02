# frozen_string_literal: true

module CommitSignatures
  class X509CommitSignature < ApplicationRecord
    include CommitSignature
    include SignatureType

    belongs_to :x509_certificate, class_name: 'X509Certificate', foreign_key: 'x509_certificate_id', optional: false

    validates :x509_certificate_id, presence: true

    def type
      :x509
    end

    def x509_commit
      return unless commit

      Gitlab::X509::Commit.new(commit)
    end

    def signed_by_user
      commit&.committer
    end

    private

    def emails_for_verification
      verified_committer_emails & x509_certificate.all_emails
    end

    def verified_committer_emails
      signed_by_user&.verified_emails || []
    end
  end
end
