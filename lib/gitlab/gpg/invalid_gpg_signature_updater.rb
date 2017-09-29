module Gitlab
  module Gpg
    class InvalidGpgSignatureUpdater
      def initialize(gpg_key)
        @gpg_key = gpg_key
        @gpg_keyids = gpg_key.subkeys.map(&:keyid).push(gpg_key.primary_keyid)
      end

      def run
        GpgSignature
          .select(:id, :commit_sha, :project_id)
          .where('gpg_key_id IS NULL OR verification_status <> ?', GpgSignature.verification_statuses[:verified])
          .where(gpg_key_primary_keyid: @gpg_keyids)
          .find_each { |sig| sig.gpg_commit.update_signature!(sig) }
      end
    end
  end
end
