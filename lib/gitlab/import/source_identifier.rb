# frozen_string_literal: true

module Gitlab
  module Import
    # Hashes the `import_source` internal event property (the source host
    # and, where applicable, path an import/migration came from). Raw values
    # count as Red data under the Data Classification Standard, so only the
    # hash may be sent to Snowplow.
    module SourceIdentifier
      def self.hash(value)
        return if value.blank?

        Gitlab::CryptoHelper.sha256(value)
      end
    end
  end
end
