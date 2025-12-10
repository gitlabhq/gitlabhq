# frozen_string_literal: true

module CommitSignatures
  class SshSignature < ApplicationRecord
    extend ::Gitlab::Utils::Override
    include CommitSignature
    include SignatureType

    belongs_to :key, optional: true
    belongs_to :user, optional: true

    override :safe_create!
    def self.safe_create!(attributes)
      create_with(attributes)
        .safe_find_or_create_by!( # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- This overrides an existent class method defined in CommitSignature concern
          project_id: attributes[:project].id,
          commit_sha: attributes[:commit_sha]
        )
    end

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
