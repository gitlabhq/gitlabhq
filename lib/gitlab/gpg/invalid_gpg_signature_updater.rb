module Gitlab
  module Gpg
    class InvalidGpgSignatureUpdater
      def initialize(gpg_key)
        @gpg_key = gpg_key
      end

      def run
        GpgSignature
          .where(valid_signature: false)
          .where(gpg_key_primary_keyid: @gpg_key.primary_keyid)
          .find_each do |gpg_signature|
            raw_commit = Gitlab::Git::Commit.find(gpg_signature.project.repository, gpg_signature.commit_sha)
            commit = ::Commit.new(raw_commit, gpg_signature.project)
            Gitlab::Gpg::Commit.new(commit).update_signature!(gpg_signature)
          end
      end
    end
  end
end
