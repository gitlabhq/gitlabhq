# frozen_string_literal: true

module CommitSignatures
  class SshSignature < ApplicationRecord
    include CommitSignature
    include SignatureType

    belongs_to :key, optional: true

    def type
      :ssh
    end

    def signed_by_user
      key&.user
    end
  end
end
