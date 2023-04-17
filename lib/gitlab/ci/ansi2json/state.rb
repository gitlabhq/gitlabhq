# frozen_string_literal: true

# In this class we keep track of the state changes that the
# Converter makes as it scans through the log stream.
module Gitlab
  module Ci
    module Ansi2json
      class State
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

          Base64.urlsafe_encode64(json, padding: false)
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

          @open_sections.delete(section)
        end

        def section_open?(section)
          @open_sections.key?(section)
        end

        def new_line!(style: nil)
          new_line = Line.new(
            offset: @offset,
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

        def decode_state(state)
          return unless state.present?

          decoded_state = Base64.urlsafe_decode64(state)
          return unless decoded_state.present?

          ::Gitlab::Json.parse(decoded_state)
        rescue ArgumentError, JSON::ParserError => error
          # This rescue is so that we don't break during the rollout or rollback
          # of `sign_and_verify_ansi2json_state`, because we may receive a
          # signed state even when the flag is disabled, and this would result
          # in invalid Base64 (ArgumentError) or invalid JSON in case the signed
          # state happens to decode as valid Base64 (JSON::ParserError).
          #
          # Once the flag has been fully rolled out this should not
          # be possible (it would imply a backend bug) and we not rescue from
          # this.
          ::Gitlab::AppLogger.warn(message: "#{self.class}: decode error", invalid_state: state, error: error)

          nil
        end
      end
    end
  end
end
