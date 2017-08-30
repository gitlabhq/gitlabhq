module Gitlab
  module Gpg
    class InvalidGpgSignatureUpdater
      def initialize(gpg_key)
        @gpg_key = gpg_key
      end

      def run
        # `OR valid_signature` is for backwards compatibility: legacy records
        # that weren't migrated to use the new `#verification_status` have
        # `#valid_signature` set instead
        GpgSignature
          .select(:id, :commit_sha, :project_id)
          .where('gpg_key_id IS NULL OR valid_signature = ? OR verification_status <> ?',
            false,
            GpgSignature.verification_statuses[:verified]
          )
          .where(gpg_key_primary_keyid: @gpg_key.primary_keyid)
          .find_each { |sig| sig.gpg_commit.update_signature!(sig) }
      end
    end
  end
end
