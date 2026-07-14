# frozen_string_literal: true

# Display the Cargo registry sparse index for a crate.
# Spec: https://doc.rust-lang.org/cargo/reference/registry-index.html#json-schema
#
# Generates the newline-delimited JSON body, one line per published version.
module Packages
  module Cargo
    class SparseIndexPresenter
      def initialize(metadata)
        @metadata = metadata
      end

      # The metadata is already ordered (most recently published first) and
      # capped by the finder, so iterate it directly. each_batch must not be
      # used here: it reorders by primary key and ignores the limit, which
      # would drop both the ordering and the version cap.
      def body
        @metadata.map { |metadatum| Gitlab::Json.dump(metadatum.index_content) }.join("\n")
      end
    end
  end
end
