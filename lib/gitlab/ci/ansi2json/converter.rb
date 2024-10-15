# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      class Converter
        # Timestamp line prefix format:
        # <timestamp> <stream number><stream type><full line type>
        # - timestamp: UTC RFC3339 timestamp
        # - stream number: 1 byte (2 hex chars) stream number
        # - stream type: E/O (Err or Out)
        # - full line type: `+` if line is continuation of previous line, ` ` otherwise
        TIMESTAMP_HEADER_REGEX = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_REGEX
        TIMESTAMP_HEADER_DATETIME_LENGTH = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_DATETIME_LENGTH
        TIMESTAMP_HEADER_LENGTH = Gitlab::Ci::Trace::Stream::TIMESTAMP_HEADER_LENGTH

        def convert(stream, new_state)
          @lines = []
          @state = State.new(new_state, stream.size)
          @has_timestamps = nil

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

          @state.new_line!(style: Style.new(**@state.inherited_style))

          process_stream_with_lookahead(stream)

          # This must be assigned before flushing the current line
          # or the @state.offset will advance to the very end
          # of the trace. Instead we want @last_line_offset to always
          # point to the beginning of last line.
          @state.set_last_line_offset

          flush_current_line

          Gitlab::Ci::Ansi2json::Result.new(
            lines: @lines,
            state: @state.encode,
            append: append,
            truncated: truncated,
            offset: start_offset,
            stream: stream
          )
        end

        private

        def process_stream(stream)
          stream.each_line do |line|
            consume_line(line)
          end
        end

        def process_stream_with_lookahead(stream)
          # We process lines with 1-line look-back, so that we can process line continuations
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
            # First line, initialize check for timestamps
            @has_timestamps = next_line.match?(TIMESTAMP_HEADER_REGEX)
            return
          end

          is_continued = @has_timestamps && next_line&.at(TIMESTAMP_HEADER_LENGTH - 1) == '+'

          # Continued lines contain an ignored \n character at the end, so we can chop it off
          line.delete_suffix!("\n") if is_continued

          if current_line_buffer.nil?
            current_line_buffer = line
          else
            # Store timestamp from continued line
            @state.current_line.add_timestamp(line[0..TIMESTAMP_HEADER_DATETIME_LENGTH - 1])

            current_line_buffer << line[TIMESTAMP_HEADER_LENGTH..]
          end

          return current_line_buffer if is_continued

          consume_line(current_line_buffer)

          nil
        end

        def consume_line(line)
          scanner = StringScanner.new(line)

          consume_token(scanner) until scanner.eos?
        end

        def consume_token(scanner)
          if @state.current_line.at_line_start?
            timestamp = get_timestamp(scanner) # Avoid regex on timestamps
            return handle_timestamp(timestamp) if timestamp
          end

          if scan_token(scanner, Gitlab::Regex.build_trace_section_regex, consume: false)
            handle_section(scanner)
          elsif scan_token(scanner, /\e([@-_])(.*?)([@-~])/)
            handle_sequence(scanner)
          elsif scan_token(scanner, /\e(?:[@-_].*?)?$/)
            # stop scanning
            scanner.terminate
          elsif scan_token(scanner, /\r*\n/)
            flush_current_line
          elsif scan_token(scanner, "\r")
            # drop last line
            @state.current_line.clear!
          elsif scan_token(scanner, /.[^\e\r\ns]*/m)
            # this is a join from all previous tokens and first letters
            # it always matches at least one character `.`
            # it matches everything that is not start of:
            # `\e`, `<`, `\r`, `\n`, `s` (for section_start)
            @state.current_line << scanner[0]
          else
            raise 'invalid parser state'
          end
        end

        def has_timestamp_prefix?(line)
          # Avoid regex on timestamps for performance
          return unless @has_timestamps && line && line.length >= TIMESTAMP_HEADER_LENGTH

          line[TIMESTAMP_HEADER_DATETIME_LENGTH - 1] == 'Z' &&
            line[4] == '-' && line[7] == '-' && line[10] == 'T' && line[13] == ':'
        end

        def get_timestamp(scanner)
          return unless @has_timestamps

          line = scanner.peek(TIMESTAMP_HEADER_LENGTH + 1)
          return unless has_timestamp_prefix?(line)

          scanner.pos += TIMESTAMP_HEADER_LENGTH
          line[0..TIMESTAMP_HEADER_DATETIME_LENGTH - 1]
        end

        def scan_token(scanner, match, consume: true)
          scanner.scan(match).tap do |result|
            # we need to move offset as soon
            # as we match the token
            @state.offset += scanner.matched_size if consume && result
          end
        end

        def handle_sequence(scanner)
          indicator = scanner[1]
          terminator = scanner[3]

          # We are only interested in color and text style changes - triggered by
          # sequences starting with '\e[' and ending with 'm'. Any other control
          # sequence gets stripped (including stuff like "delete last line")
          return unless indicator == '[' && terminator == 'm'

          commands = scanner[2].split ';'
          @state.update_style(commands)
        end

        def handle_timestamp(timestamp)
          @state.current_line.add_timestamp(timestamp)
          @state.offset += TIMESTAMP_HEADER_LENGTH
        end

        def handle_section(scanner)
          action = scanner[1]
          timestamp = scanner[2]
          section = scanner[3]

          section_name = sanitize_section_name(section)

          case action
          when 'start'
            options = parse_section_options(scanner[4])
            handle_section_start(scanner, section_name, timestamp, options)
          when 'end'
            handle_section_end(scanner, section_name, timestamp)
          else
            raise 'unsupported action'
          end
        end

        def handle_section_start(scanner, section, section_timestamp, options)
          # We make a new line for new section
          flush_current_line(false)

          @state.open_section(section, section_timestamp, options)

          # we need to consume match after handling
          # the open of section, as we want the section
          # marker to be refresh on incremental update
          @state.offset += scanner.matched_size
        end

        def handle_section_end(scanner, section, section_timestamp)
          unless @state.section_open?(section)
            @state.offset += scanner.matched_size
            return
          end

          # We flush the content to make the end
          # of section to be a new line
          flush_current_line(false)

          @state.close_section(section, section_timestamp)

          # we need to consume match before handling
          # as we want the section close marker
          # not to be refreshed on incremental update
          @state.offset += scanner.matched_size

          # this flushes an empty line with `section_duration`
          flush_current_line(false)
        end

        def flush_current_line(hard_flush = true)
          current_line = @state.current_line

          unless current_line.empty?
            @lines << current_line.to_h
          end

          if hard_flush
            # Account for timestamps in line continuations plus the chopped \n at each preceding continued line
            continuation_line_count = current_line.timestamps.count - 1
            @state.offset += (TIMESTAMP_HEADER_LENGTH + 1) * continuation_line_count if continuation_line_count > 0
            @state.new_line!
          else
            new_line_offset = @state.offset
            # Discount offset from timestamp content if we're still at the beginning of the line
            new_line_offset -= TIMESTAMP_HEADER_LENGTH if current_line.empty? && current_line.timestamps.any?
            # Preserve timestamps from current line, since this is a soft flush
            @state.new_line!(offset: new_line_offset, timestamps: @state.current_line.timestamps)
          end
        end

        def sanitize_section_name(section)
          section.to_s.downcase.gsub(/[^a-z0-9]/, '-')
        end

        def parse_section_options(raw_options)
          return unless raw_options

          # We need to remove the square brackets and split
          # by comma to get a list of the options
          options = raw_options[1...-1].split ','

          # Now split each option by equals to separate
          # each in the format [key, value]
          options.to_h { |option| option.split '=' }
        end
      end
    end
  end
end
