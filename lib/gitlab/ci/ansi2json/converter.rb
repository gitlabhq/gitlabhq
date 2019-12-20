# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      class Converter
        def convert(stream, new_state)
          @lines = []
          @state = State.new(new_state, stream.size)

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

          @state.new_line!(
            style: Style.new(@state.inherited_style))

          stream.each_line do |line|
            consume_line(line)
          end

          # This must be assigned before flushing the current line
          # or the @current_line.offset will advance to the very end
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

        def consume_line(line)
          scanner = StringScanner.new(line)

          consume_token(scanner) until scanner.eos?
        end

        def consume_token(scanner)
          if scan_token(scanner, Gitlab::Regex.build_trace_section_regex, consume: false)
            handle_section(scanner)
          elsif scan_token(scanner, /\e([@-_])(.*?)([@-~])/)
            handle_sequence(scanner)
          elsif scan_token(scanner, /\e(([@-_])(.*?)?)?$/)
            # stop scanning
            scanner.terminate
          elsif scan_token(scanner, /\r?\n/)
            flush_current_line
          elsif scan_token(scanner, /\r/)
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

        def scan_token(scanner, match, consume: true)
          scanner.scan(match).tap do |result|
            # we need to move offset as soon
            # as we match the token
            @state.offset += scanner.matched_size if consume && result
          end
        end

        def handle_sequence(scanner)
          indicator = scanner[1]
          commands = scanner[2].split ';'
          terminator = scanner[3]

          # We are only interested in color and text style changes - triggered by
          # sequences starting with '\e[' and ending with 'm'. Any other control
          # sequence gets stripped (including stuff like "delete last line")
          return unless indicator == '[' && terminator == 'm'

          @state.update_style(commands)
        end

        def handle_section(scanner)
          action = scanner[1]
          timestamp = scanner[2]
          section = scanner[3]

          section_name = sanitize_section_name(section)

          if action == "start"
            handle_section_start(scanner, section_name, timestamp)
          elsif action == "end"
            handle_section_end(scanner, section_name, timestamp)
          else
            raise 'unsupported action'
          end
        end

        def handle_section_start(scanner, section, timestamp)
          # We make a new line for new section
          flush_current_line

          @state.open_section(section, timestamp)

          # we need to consume match after handling
          # the open of section, as we want the section
          # marker to be refresh on incremental update
          @state.offset += scanner.matched_size
        end

        def handle_section_end(scanner, section, timestamp)
          return unless @state.section_open?(section)

          # We flush the content to make the end
          # of section to be a new line
          flush_current_line

          @state.close_section(section, timestamp)

          # we need to consume match before handling
          # as we want the section close marker
          # not to be refreshed on incremental update
          @state.offset += scanner.matched_size

          # this flushes an empty line with `section_duration`
          flush_current_line
        end

        def flush_current_line
          unless @state.current_line.empty?
            @lines << @state.current_line.to_h
          end

          @state.new_line!
        end

        def sanitize_section_name(section)
          section.to_s.downcase.gsub(/[^a-z0-9]/, '-')
        end
      end
    end
  end
end
