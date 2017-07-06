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
            Gitlab::Gpg::Commit.new(gpg_signature.commit).update_signature!(gpg_signature)
          end
      end
    end
  end
end
