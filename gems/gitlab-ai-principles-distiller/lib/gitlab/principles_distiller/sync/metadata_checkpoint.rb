# frozen_string_literal: true

require 'openssl'

module Gitlab
  module PrinciplesDistiller
    class Sync
      # The frontmatter a successful no-change distillation should record, so the next scan skips the principle until
      # its sources change again.
      #
      # `original_sha256` fingerprints the whole distilled file that was evaluated, frontmatter included.
      # Applying the checkpoint to any other file content is refused: a changed body means the evaluation no longer
      # describes it, and changed frontmatter means newer metadata already landed and must not be regressed.
      MetadataCheckpoint = Data.define(:source_checksum, :distilled_at_sha, :original_sha256) do
        def self.fingerprint(content)
          OpenSSL::Digest::SHA256.hexdigest(content)
        end

        def self.from_h(hash)
          new(**hash.transform_keys(&:to_sym).slice(*members))
        end

        # Returns `content` with only the two frontmatter values replaced, or nil when `content` is not the file that
        # was evaluated. The body after the frontmatter is preserved byte-for-byte.
        def apply(content)
          return unless content.start_with?("---\n")
          return unless self.class.fingerprint(content) == original_sha256

          _empty, frontmatter, body = content.split("---\n", 3)
          return unless body

          frontmatter = set_key(frontmatter, 'source_checksum', source_checksum)
          frontmatter = set_key(frontmatter, 'distilled_at_sha', distilled_at_sha)

          "---\n#{frontmatter}---\n#{body}"
        end

        private

        def set_key(frontmatter, key, value)
          line = "#{key}: #{value}\n"
          pattern = /^#{Regexp.escape(key)}:.*\n/
          return frontmatter.sub(pattern, line) if frontmatter.match?(pattern)

          "#{frontmatter}#{line}"
        end
      end
    end
  end
end
