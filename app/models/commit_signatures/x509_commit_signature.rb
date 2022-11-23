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
  end
end
