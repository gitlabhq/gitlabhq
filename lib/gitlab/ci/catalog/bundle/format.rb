# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        # Collected files are stored as JSON strings, so they round-trip byte for byte
        # and are never parsed as part of the bundle.
        class Format
          VERSION = 1

          def self.dump(name:, version:, sha:, entry_path:, files:)
            ::Gitlab::Json.dump(
              format_version: VERSION,
              name: name,
              version: version,
              sha: sha,
              entry_path: entry_path,
              files: files
            )
          end
        end
      end
    end
  end
end
