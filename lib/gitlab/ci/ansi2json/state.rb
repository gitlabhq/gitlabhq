# frozen_string_literal: true

require 'openssl'

# In this class we keep track of the state changes that the
# Converter makes as it scans through the log stream.
module Gitlab
  module Ci
    module Ansi2json
      class State
        include Gitlab::Utils::StrongMemoize

        SIGNATURE_KEY_SALT = 'gitlab-ci-ansi2json-state'
        SEPARATOR = '--'

        attr_accessor :offset, :current_line, :inherited_style, :open_sections, :last_line_offset

        def initialize(new_state, stream_size)
          @offset = 0
          @inherited_style = {}
          @open_sections = {}
          @stream_size = stream_size

          restore_state!(new_state)
        end

        def encode
          json = {
            offset: @last_line_offset,
            style: @current_line.style.to_h,
            open_sections: @open_sections
          }.to_json

          encoded = Base64.urlsafe_encode64(json, padding: false)

          encoded + SEPARATOR + sign(encoded)
        end

        def open_section(section, timestamp, options)
          @open_sections[section] = timestamp

          @current_line.add_section(section)
          @current_line.set_section_options(options)
          @current_line.set_as_section_header
        end

        def close_section(section, timestamp)
          return unless section_open?(section)

          duration = timestamp.to_i - @open_sections[section].to_i
          @current_line.set_section_duration(duration)
          @current_line.set_as_section_footer

          @open_sections.delete(section)
        end

        def section_open?(section)
          @open_sections.key?(section)
        end

        def new_line!(timestamps: [], offset: nil, style: nil)
          new_line = Line.new(
            offset: offset || @offset,
            timestamps: timestamps,
            style: style || @current_line.style,
            sections: @open_sections.keys
          )
          @current_line = new_line
        end

        def set_last_line_offset
          @last_line_offset = @current_line.offset
        end

        def update_style(commands)
          @current_line.flush_current_segment!
          @current_line.update_style(commands)
        end

        private

        def restore_state!(encoded_state)
          state = decode_state(encoded_state)

          return unless state
          return if state['offset'].to_i > @stream_size

          @offset = state['offset'].to_i if state['offset']
          @open_sections = state['open_sections'] if state['open_sections']

          if state['style']
            @inherited_style = {
              fg: state.dig('style', 'fg'),
              bg: state.dig('style', 'bg'),
              mask: state.dig('style', 'mask')
            }
          end
        end

        def decode_state(data)
          return if data.blank?

          encoded_state = verify(data)
          if encoded_state.blank?
            ::Gitlab::AppLogger.warn(message: "#{self.class}: signature missing or invalid", invalid_state: data)
            return
          end

          decoded_state = Base64.urlsafe_decode64(encoded_state)
          return unless decoded_state.present?

          ::Gitlab::Json.parse(decoded_state)
        end

        def sign(message)
          ::OpenSSL::HMAC.hexdigest(
            signature_digest,
            signature_key,
            message
          )
        end

        def verify(signed_message)
          signature_length = signature_digest.digest_length * 2 # a byte is exactly two hexadecimals
          message_length = signed_message.length - SEPARATOR.length - signature_length
          return if message_length <= 0

          signature = signed_message.last(signature_length)
          message = signed_message.first(message_length)
          return unless valid_signature?(message, signature)

          message
        end

        def valid_signature?(message, signature)
          expected_signature = sign(message)
          expected_signature.bytesize == signature.bytesize &&
            ::OpenSSL.fixed_length_secure_compare(signature, expected_signature)
        end

        def signature_digest
          ::OpenSSL::Digest.new('SHA256')
        end

        def signature_key
          ::Gitlab::Application.key_generator.generate_key(SIGNATURE_KEY_SALT, signature_digest.block_length)
        end
        strong_memoize_attr :signature_key
      end
    end
  end
end
