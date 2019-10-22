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

          @state.set_current_line!(style: Style.new(@state.inherited_style))

          stream.each_line do |line|
            s = StringScanner.new(line)
            convert_line(s)
          end

          # This must be assigned before flushing the current line
          # or the @current_line.offset will advance to the very end
          # of the trace. Instead we want @last_line_offset to always
          # point to the beginning of last line.
          @state.set_last_line_offset

          flush_current_line

          # TODO: replace OpenStruct with a better type
          # https://gitlab.com/gitlab-org/gitlab/issues/34305
          OpenStruct.new(
            lines: @lines,
            state: @state.encode,
            append: append,
            truncated: truncated,
            offset: start_offset,
            size: stream.tell - start_offset,
            total: stream.size
          )
        end

        private

        def convert_line(scanner)
          until scanner.eos?

            if scanner.scan(Gitlab::Regex.build_trace_section_regex)
              handle_section(scanner)
            elsif scanner.scan(/\e([@-_])(.*?)([@-~])/)
              handle_sequence(scanner)
            elsif scanner.scan(/\e(([@-_])(.*?)?)?$/)
              break
            elsif scanner.scan(/</)
              @state.current_line << '&lt;'
            elsif scanner.scan(/\r?\n/)
              # we advance the offset of the next current line
              # so it does not start from \n
              flush_current_line(advance_offset: scanner.matched_size)
            else
              @state.current_line << scanner.scan(/./m)
            end

            @state.offset += scanner.matched_size
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
            handle_section_start(section_name, timestamp)
          elsif action == "end"
            handle_section_end(section_name, timestamp)
          end
        end

        def handle_section_start(section, timestamp)
          flush_current_line unless @state.current_line.empty?
          @state.open_section(section, timestamp)
        end

        def handle_section_end(section, timestamp)
          return unless @state.section_open?(section)

          flush_current_line unless @state.current_line.empty?
          @state.close_section(section, timestamp)

          # ensure that section end is detached from the last
          # line in the section
          flush_current_line
        end

        def flush_current_line(advance_offset: 0)
          @lines << @state.current_line.to_h

          @state.set_current_line!(advance_offset: advance_offset)
        end

        def sanitize_section_name(section)
          section.to_s.downcase.gsub(/[^a-z0-9]/, '-')
        end
      end
    end
  end
end
