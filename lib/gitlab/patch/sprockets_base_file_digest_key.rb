# frozen_string_literal: true

# This monkey patch prevent cache ballooning when caching tmp/cache/assets/sprockets
# on the CI. See https://github.com/rails/sprockets/issues/563 and
# https://github.com/rails/sprockets/compare/3.x...jmreid:no-mtime-for-digest-key.
module Gitlab
  module Patch
    module SprocketsBaseFileDigestKey
      def file_digest(path)
        if stat = self.stat(path)
          digest = self.stat_digest(path, stat)
          integrity_uri = self.integrity_uri(digest)

          key = Sprockets::UnloadedAsset.new(path, self).file_digest_key(integrity_uri)
          cache.fetch(key) do
            digest
          end
        end
      end
    end
  end
end
