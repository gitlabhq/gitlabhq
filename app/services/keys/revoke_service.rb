# frozen_string_literal: true

module Keys
  class RevokeService < ::Keys::DestroyService
    def execute(key)
      key.transaction do
        unverify_associated_signatures(key)

        raise ActiveRecord::Rollback unless super(key)
      end
    end

    private

    def unverify_associated_signatures(key)
      key.ssh_signatures.each_batch do |batch|
        batch.update_all(
          verification_status: CommitSignatures::SshSignature.verification_statuses[:revoked_key],
          updated_at: Time.zone.now
        )
      end
    end
  end
end

Keys::DestroyService.prepend_mod
