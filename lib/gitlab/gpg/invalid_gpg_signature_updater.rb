# frozen_string_literal: true

module Gitlab
  module Gpg
    class InvalidGpgSignatureUpdater
      def initialize(gpg_key)
        @gpg_key = gpg_key
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def run
        CommitSignatures::GpgSignature
          .select(:id, :commit_sha, :project_id)
          .where('gpg_key_id IS NULL OR verification_status <> ?', CommitSignatures::GpgSignature.verification_statuses[:verified])
          .where(gpg_key_primary_keyid: @gpg_key.keyids)
          .find_each { |sig| sig.gpg_commit&.update_signature!(sig) }
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
