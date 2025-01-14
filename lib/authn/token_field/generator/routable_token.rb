# frozen_string_literal: true

module Authn
  module TokenField
    module Generator
      class RoutableToken
        RANDOM_BYTES_LENGTH = 16
        BASE64_PAYLOAD_LENGTH_HOLDER_BYTES = 2
        CRC_BYTES = 7
        VALID_ROUTING_KEYS = %i[c g o p u].freeze
        REQUIRED_ROUTING_KEYS = %i[o].freeze
        MAXIMUM_SIZE_OF_ROUTING_PAYLOAD = 159
        DEFAULT_ROUTING_PAYLOAD_HASH =
          {
            c: ->(_) { Settings.cell[:id] }
          }.freeze

        PayloadTooLarge = Class.new(RuntimeError)
        MissingRequiredRoutingKeys = Class.new(ArgumentError)
        InvalidRoutingKeys = Class.new(ArgumentError)

        def self.random_bytes(length)
          SecureRandom.random_bytes(length)
        end

        attr_reader :token_owner_record, :routing_payload, :prefix

        def initialize(token_owner_record, routing_payload:, prefix: '')
          @token_owner_record = token_owner_record
          @routing_payload = routing_payload
          @prefix = prefix

          validate_routing_keys!
        end

        def generate_token
          routing_hash
            .then { |routing_hash| build_payload(routing_hash) }
            .then { |payload| check_payload_size!(payload) }
            .then { |payload| encode_payload(payload, self.class.random_bytes(RANDOM_BYTES_LENGTH)) }
            .then { |encoded_payload| append_crc(encoded_payload) }
        end

        private

        def validate_routing_keys!
          check_required_routing_keys!
          check_invalid_routing_keys!
        end

        def routing_hash
          routing_payload
            .merge(DEFAULT_ROUTING_PAYLOAD_HASH)
            .transform_values { |generator| format_value(generator.call(token_owner_record)) }
            .compact_blank
            .sort
        end

        def build_payload(routing_hash)
          routing_hash.map { |k, v| "#{k}:#{v}" }.join("\n")
        end

        def format_value(value)
          value.is_a?(Integer) ? value.to_s(36) : value
        end

        def encode_payload(payload, random_bytes)
          encodable_payload = "#{payload}#{random_bytes}#{[random_bytes.size].pack('C')}"
          base64_payload = Base64.urlsafe_encode64(encodable_payload, padding: false)
          base64_payload_length = base64_payload.size.to_s(36).rjust(BASE64_PAYLOAD_LENGTH_HOLDER_BYTES, '0')
          "#{prefix}#{base64_payload}.#{base64_payload_length}"
        end

        def append_crc(encoded_payload)
          crc = Zlib.crc32(encoded_payload).to_s(36).rjust(CRC_BYTES, '0')
          "#{encoded_payload}#{crc}"
        end

        def check_required_routing_keys!
          missing_keys = REQUIRED_ROUTING_KEYS - routing_payload.keys
          return if missing_keys.empty?

          raise MissingRequiredRoutingKeys, missing_keys_error_message(missing_keys)
        end

        def check_invalid_routing_keys!
          invalid_keys = routing_payload.keys - VALID_ROUTING_KEYS
          return if invalid_keys.empty?

          raise InvalidRoutingKeys, invalid_keys_error_message(invalid_keys)
        end

        def check_payload_size!(payload)
          return payload if payload.size <= MAXIMUM_SIZE_OF_ROUTING_PAYLOAD

          raise PayloadTooLarge, payload_size_error_message(payload.size)
        end

        def missing_keys_error_message(missing_keys)
          "Missing required routing keys: #{missing_keys.map(&:inspect).join(', ')}. " \
            "Required routing keys are: #{REQUIRED_ROUTING_KEYS.map(&:inspect).join(', ')}."
        end

        def invalid_keys_error_message(invalid_keys)
          "Invalid routing keys: #{invalid_keys.map(&:inspect).join(', ')}. " \
            "Valid routing keys are: #{VALID_ROUTING_KEYS.map(&:inspect).join(', ')}."
        end

        def payload_size_error_message(size)
          "Routing payload is too big: #{size}. " \
            "Maximum size is #{MAXIMUM_SIZE_OF_ROUTING_PAYLOAD}."
        end
      end
    end
  end
end
