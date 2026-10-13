# frozen_string_literal: true

module Packages
  module Cargo
    class ExtractMetadataContentService
      LENGTH_BYTE_SIZE = 4
      MAX_CRATE_BYTE_SIZE = 10.megabytes
      # Client sets this length; cap it to avoid a huge read.
      MAX_INDEX_BYTE_SIZE = 10.megabytes

      def initialize(cargo_file_content)
        # IO-like object (File, Tempfile, StringIO, etc.)
        cargo_file_content&.rewind
        @cargo_file_content = cargo_file_content
      end

      def execute
        ServiceResponse.success(payload: extract_metadata)
      rescue JSON::ParserError => e
        ServiceResponse.error(message: "Invalid JSON metadata: #{e.message}")
      rescue EOFError, StandardError => e
        ServiceResponse.error(message: "Failed to extract metadata: #{e.message}")
      end

      # The metadata is length-prefixed at the front of the publish body, so a
      # request-time check can read it without pulling the crate (up to
      # MAX_CRATE_BYTE_SIZE) into memory the way #execute does. Rewinds on the
      # way out because the caller still has to upload the same IO.
      def execute_index_only
        ServiceResponse.success(payload: { index_content: read_index_content })
      rescue JSON::ParserError => e
        ServiceResponse.error(message: "Invalid JSON metadata: #{e.message}")
      rescue EOFError, StandardError => e
        ServiceResponse.error(message: "Failed to extract metadata: #{e.message}")
      ensure
        @cargo_file_content&.rewind
      end

      private

      # Reference: https://doc.rust-lang.org/cargo/reference/registry-web-api.html#publish
      def extract_metadata
        index_content = read_index_content

        crate_length = read_length('crate')
        raise ArgumentError, "Crate size exceeds maximum allowed" if crate_length > MAX_CRATE_BYTE_SIZE

        crate_data = read_content(length: crate_length)

        { index_content: index_content, crate_data: crate_data }
      end

      def read_exact(length, label)
        data = @cargo_file_content.read(length)
        raise EOFError, "Unexpected EOF while reading #{label}" if data.nil? || data.bytesize < length

        data
      end

      def read_length(label)
        bytes = read_exact(LENGTH_BYTE_SIZE, "#{label} length")
        length = bytes.unpack1('L<')
        raise ArgumentError, "#{label} length must be positive" if length <= 0

        length
      end

      def read_index_content
        json_length = read_length('JSON')
        raise ArgumentError, "Metadata size exceeds maximum allowed" if json_length > MAX_INDEX_BYTE_SIZE

        read_json(length: json_length)
      end

      def read_json(length:)
        json_data = read_exact(length, "index data")
        Gitlab::Json.safe_parse(json_data).deep_symbolize_keys
      end

      def read_content(length:)
        read_exact(length, "crate data")
      end
    end
  end
end
