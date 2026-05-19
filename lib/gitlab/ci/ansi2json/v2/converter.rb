# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      module V2
        class Converter
          TIMESTAMP_HEADER_REGEX = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_REGEX
          TIMESTAMP_HEADER_DATETIME_LENGTH = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_DATETIME_LENGTH
          TIMESTAMP_HEADER_LENGTH = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_LENGTH

          SECTION_REGEX = Gitlab::Regex.build_trace_section_regex
          CRLF_REGEX = /\r*\n/
          PLAIN_TEXT_RUN = /.[^\e\r\ns]*/m

          def convert(stream, new_state)
            @lines = []
            @state = State.new(new_state, stream.size)
            @has_timestamps = nil
            @scanner = StringScanner.new('')

            append = false
            truncated = false

            cur_offset = stream.tell
            if cur_offset > @state.offset
              @state.offset = cur_offset
              truncated = true
            else
              stream.seek(@state.offset)
              append = @state.offset > 0
            end

            start_offset = @state.offset

            @state.new_line!(style: AnsiEvaluator.new(**@state.inherited_style))

            process_stream_with_lookahead(stream)

            @state.set_last_line_offset
            flush_current_line

            ::Gitlab::Ci::Ansi2json::Result.new(
              lines: @lines,
              state: @state.encode,
              append: append,
              truncated: truncated,
              offset: start_offset,
              stream: stream
            )
          end

          private

          def process_stream_with_lookahead(stream)
            previous_line = nil
            current_line_buffer = nil

            stream.each_line do |line|
              current_line_buffer = handle_line(previous_line, line, current_line_buffer)
              previous_line = line
            end

            handle_line(previous_line, nil, current_line_buffer) if previous_line
          end

          def handle_line(line, next_line, current_line_buffer)
            if line.nil?
              @has_timestamps = next_line.match?(TIMESTAMP_HEADER_REGEX)
              return
            end

            is_continued = @has_timestamps && next_line&.at(TIMESTAMP_HEADER_LENGTH - 1) == '+'

            line.delete_suffix!("\n") if is_continued

            if current_line_buffer.nil?
              current_line_buffer = line
            else
              @state.current_line.add_timestamp(line[0..(TIMESTAMP_HEADER_DATETIME_LENGTH - 1)])
              current_line_buffer << line[TIMESTAMP_HEADER_LENGTH..]
            end

            return current_line_buffer if is_continued

            consume_line(current_line_buffer)
            nil
          end

          def consume_line(line)
            @scanner.string = line
            consume_token(@scanner) until @scanner.eos?
          end

          def consume_token(scanner)
            return if @has_timestamps && @state.current_line.at_line_start? && try_consume_timestamp(scanner)

            case scanner.string.getbyte(scanner.pos)
            when 0x1b # \e
              consume_escape(scanner)
            when 0x0a # \n
              scanner.pos += 1
              @state.offset += 1
              flush_current_line
            when 0x0d # \r
              if scanner.scan(CRLF_REGEX)
                @state.offset += scanner.matched_size
                flush_current_line
              else
                scanner.pos += 1
                @state.offset += 1
                @state.current_line.clear!
              end
            when 0x73 # 's', possible section_ prefix
              if scanner.scan(SECTION_REGEX)
                handle_section(scanner)
              else
                consume_plain_text(scanner)
              end
            else
              consume_plain_text(scanner)
            end
          end

          def consume_plain_text(scanner)
            text = scanner.scan(PLAIN_TEXT_RUN)
            return unless text

            @state.offset += text.bytesize
            @state.current_line << text
          end

          # Cursor-based CSI parser. Only \e[...m sequences trigger style
          # updates; other escapes are silently consumed (matches v1).
          # Branches kept inline to avoid helper dispatch overhead on the
          # per-byte hot path.
          # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity -- intentional
          def consume_escape(scanner)
            string = scanner.string
            len = string.bytesize
            start = scanner.pos
            pos = start + 1

            if pos >= len
              scanner.terminate
              return
            end

            indicator = string.getbyte(pos)

            unless indicator >= 0x40 && indicator <= 0x5f
              scanner.pos = pos
              @state.offset += 1
              return
            end

            pos += 1

            param_start = pos
            while pos < len && (b = string.getbyte(pos)) >= 0x30 && b <= 0x3f
              pos += 1
            end
            param_end = pos

            while pos < len && (b = string.getbyte(pos)) >= 0x20 && b <= 0x2f
              pos += 1
            end

            if pos >= len
              scanner.terminate
              return
            end

            terminator = string.getbyte(pos)
            unless terminator >= 0x40 && terminator <= 0x7e
              scanner.terminate
              return
            end

            pos += 1
            scanner.pos = pos
            @state.offset += pos - start

            return unless indicator == 0x5b && terminator == 0x6d

            if param_end == param_start
              @state.update_style([])
            else
              params = string.byteslice(param_start, param_end - param_start)
              @state.update_style(params.split(';'))
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

          # Cheaper than re-running the timestamp regex per line: a manual
          # check on the bytes that must be present in an RFC3339 timestamp.
          def try_consume_timestamp(scanner)
            string = scanner.string
            pos = scanner.pos
            return false if string.bytesize - pos < TIMESTAMP_HEADER_LENGTH

            return false unless string.getbyte(pos + TIMESTAMP_HEADER_DATETIME_LENGTH - 1) == 0x5a # 'Z'
            return false unless string.getbyte(pos + 4)  == 0x2d # '-'
            return false unless string.getbyte(pos + 7)  == 0x2d # '-'
            return false unless string.getbyte(pos + 10) == 0x54 # 'T'
            return false unless string.getbyte(pos + 13) == 0x3a # ':'

            timestamp = string.byteslice(pos, TIMESTAMP_HEADER_DATETIME_LENGTH)
            scanner.pos = pos + TIMESTAMP_HEADER_LENGTH
            @state.current_line.add_timestamp(timestamp)
            @state.offset += TIMESTAMP_HEADER_LENGTH
            true
          end

          def handle_section(scanner)
            action = scanner[1]
            timestamp = scanner[2]
            section_name = sanitize_section_name(scanner[3])

            case action
            when 'start'
              handle_section_start(scanner, section_name, timestamp, parse_section_options(scanner[4]))
            when 'end'
              handle_section_end(scanner, section_name, timestamp)
            else
              raise 'unsupported action'
            end
          end

          def handle_section_start(scanner, section, section_timestamp, options)
            flush_current_line(false)
            @state.open_section(section, section_timestamp, options)
            @state.offset += scanner.matched_size
          end

          def handle_section_end(scanner, section, section_timestamp)
            unless @state.section_open?(section)
              @state.offset += scanner.matched_size
              return
            end

            flush_current_line(false)
            @state.close_section(section, section_timestamp)
            @state.offset += scanner.matched_size
            flush_current_line(false)
          end

          def flush_current_line(hard_flush = true)
            current_line = @state.current_line

            @lines << current_line.to_h unless current_line.empty?

            if hard_flush
              continuation_line_count = current_line.timestamps.count - 1
              @state.offset += (TIMESTAMP_HEADER_LENGTH + 1) * continuation_line_count if continuation_line_count > 0
              @state.new_line!
            else
              new_line_offset = @state.offset
              new_line_offset -= TIMESTAMP_HEADER_LENGTH if current_line.empty? && current_line.timestamps.any?
              @state.new_line!(offset: new_line_offset, timestamps: @state.current_line.timestamps)
            end
          end

          def sanitize_section_name(section)
            section.to_s.downcase.gsub(/[^a-z0-9]/, '-')
          end

          def parse_section_options(raw_options)
            return unless raw_options

            raw_options[1...-1].split(',').to_h { |option| option.split('=') }
          end
        end
      end
    end
  end
end
