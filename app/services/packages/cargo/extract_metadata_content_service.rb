# frozen_string_literal: true

module Packages
  module Cargo
    class ExtractMetadataContentService
      LENGTH_BYTE_SIZE = 4
      MAX_CRATE_BYTE_SIZE = 10.megabytes

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

      private

      # Reference: https://doc.rust-lang.org/cargo/reference/registry-web-api.html#publish
      def extract_metadata
        index_length = read_length('JSON')
        index_content = read_json(length: index_length)

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
