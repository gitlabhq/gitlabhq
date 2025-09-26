# frozen_string_literal: true

module Gitlab
  module Terraform
    # This streaming JSON handler extracts the `serial` keyword from the Terraform
    # state API. This is faster and more efficient than running `JSON.parse(data)['serial']`
    # particularly for large JSON blobs.
    class ScHandler < ::Oj::ScHandler
      attr_reader :serial

      def initialize
        @serial = nil
        @depth = 0
      end

      def hash_start
        @depth += 1
      end

      def hash_end
        @depth -= 1
      end

      def hash_set(_hash, key, value)
        return unless @depth == 1 && key == 'serial'

        @serial = value
      end
    end

    class StateParser
      def self.extract_serial(data)
        handler = ::Gitlab::Terraform::ScHandler.new

        begin
          ::Oj.sc_parse(handler, data)
          handler.serial
        rescue Oj::ParseError, EncodingError, TypeError => e
          # Actual parsing errors
          raise ::JSON::ParserError, e.to_s
        end
      end
    end
  end
end
