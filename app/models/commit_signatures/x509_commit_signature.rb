# frozen_string_literal: true
module CommitSignatures
  class X509CommitSignature < ApplicationRecord
    include CommitSignature

    belongs_to :x509_certificate, class_name: 'X509Certificate', foreign_key: 'x509_certificate_id', optional: false

    validates :x509_certificate_id, presence: true

    def x509_commit
      return unless commit

      Gitlab::X509::Commit.new(commit)
    end
  end
end
