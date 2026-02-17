# frozen_string_literal: true

module Authn
  module TokenField
    module Decoders
      module V1
        class RoutablePayload
          def initialize(token)
            @token = token
          end

          def decode
            return unless routable_token?

            decoded_payload_hash
          end

          private

          attr_reader :token

          def routable_token?
            generator_class.crc_of(prefixed_encoded_payload) == crc
          end

          def decoded_payload_hash
            formatted_payload.try do |str|
              pairs = str.split("\n").filter(&:present?).compact
              break if pairs.blank?

              pairs = pairs.map { |pair| pair.split(':') }
              break if pairs.any? { |pair| pair.length != 2 }

              pairs.to_h.transform_values { |v| v.to_i(36) }
            end
          end

          def formatted_payload
            decodable_payload.try { |payload| payload[generator_class::RANDOM_BYTES_LENGTH...-1] }
          end

          def decodable_payload
            base64_payload.try { |payload| Base64.urlsafe_decode64(payload) }
          end

          def base64_payload
            prefixed_base64_payload, _, base64_payload_length = prefixed_encoded_payload.split('.')
            return if base64_payload_length.blank?

            prefixed_base64_payload[-base64_payload_length.to_i(36)..]
          end

          def prefixed_encoded_payload
            token[...-generator_class::CRC_BYTES]
          end

          def crc
            token[-generator_class::CRC_BYTES..]
          end

          def generator_class
            ::Authn::TokenField::Generator::RoutableToken
          end
        end
      end
    end
  end
end
