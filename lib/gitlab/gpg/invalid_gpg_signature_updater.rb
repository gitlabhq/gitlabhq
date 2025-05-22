# frozen_string_literal: true

module Gitlab
  module Gpg
    class InvalidGpgSignatureUpdater
      def initialize(gpg_key)
        @gpg_key = gpg_key
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def run
        [@gpg_key].concat(@gpg_key.subkeys).each do |key|
          Gitlab::Gpg.using_tmp_keychain do
            Gitlab::Gpg::CurrentKeyChain.add(key.key)
            CommitSignatures::GpgSignature
              .select(:id, :commit_sha, :project_id)
              .where('gpg_key_id IS NULL OR verification_status <> ?', CommitSignatures::GpgSignature.verification_statuses[:verified])
              .where(gpg_key_primary_keyid: [key.keyid, key.fingerprint])
              .find_each do |sig|
                sig.gpg_commit&.update_signature_with_keychain!(sig, key)
              end
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
