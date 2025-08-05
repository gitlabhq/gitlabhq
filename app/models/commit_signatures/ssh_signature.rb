# frozen_string_literal: true

module CommitSignatures
  class SshSignature < ApplicationRecord
    include CommitSignature
    include SignatureType

    belongs_to :key, optional: true
    belongs_to :user, optional: true

    ignore_column :author_email, remove_with: '18.5', remove_after: '2025-09-13'

    def type
      :ssh
    end

    def signed_by_user
      user || key&.user
    end

    def key_fingerprint_sha256
      super || key&.fingerprint_sha256
    end
  end
end
