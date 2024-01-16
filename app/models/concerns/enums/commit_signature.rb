# frozen_string_literal: true

module Enums
  class CommitSignature
    VERIFICATION_STATUSES = {
      unverified: 0,
      verified: 1,
      same_user_different_email: 2,
      other_user: 3,
      unverified_key: 4,
      unknown_key: 5,
      multiple_signatures: 6,
      revoked_key: 7,
      verified_system: 8
      # EE adds more values in ee/app/models/concerns/ee/enums/commit_signature.rb
    }.freeze

    def self.verification_statuses
      VERIFICATION_STATUSES
    end
  end
end

Enums::CommitSignature.prepend_mod
