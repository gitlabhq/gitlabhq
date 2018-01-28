module Gitlab
  module Ci
    class Trace
      class SectionParser
        def initialize(lines)
          @lines = lines
        end

        def parse!
          @markers = {}

          @lines.each do |line, pos|
            parse_line(line, pos)
          end
        end

        def sections
          sanitize_markers.map do |name, markers|
            start_, end_ = markers

            {
              name: name,
              byte_start: start_[:marker],
              byte_end: end_[:marker],
              date_start: start_[:timestamp],
              date_end: end_[:timestamp]
            }
          end
        end

        private

        def parse_line(line, line_start_position)
          s = StringScanner.new(line)
          until s.eos?
            find_next_marker(s) do |scanner|
              marker_begins_at = line_start_position + scanner.pointer

              if scanner.scan(Gitlab::Regex.build_trace_section_regex)
                marker_ends_at = line_start_position + scanner.pointer
                handle_line(scanner[1], scanner[2].to_i, scanner[3], marker_begins_at, marker_ends_at)
                true
              else
                false
              end
            end
          end
        end

        def sanitize_markers
          @markers.select do |_, markers|
            markers.size == 2 && markers[0][:action] == :start && markers[1][:action] == :end
          end
        end

        def handle_line(action, time, name, marker_start, marker_end)
          action = action.to_sym
          timestamp = Time.at(time).utc
          marker = if action == :start
                     marker_end
                   else
                     marker_start
                   end

          @markers[name] ||= []
          @markers[name] << {
            name: name,
            action: action,
            timestamp: timestamp,
            marker: marker
          }
        end

        def beginning_of_section_regex
          @beginning_of_section_regex ||= /section_/.freeze
        end

        def find_next_marker(s)
          beginning_of_section_len = 8
          maybe_marker = s.exist?(beginning_of_section_regex)

          if maybe_marker.nil?
            s.terminate
          else
            # repositioning at the beginning of the match
            s.pos += maybe_marker - beginning_of_section_len
            if block_given?
              good_marker = yield(s)
              # if not a good marker: Consuming the matched beginning_of_section_regex
              s.pos += beginning_of_section_len unless good_marker
            end
          end
        end
      end
    end
  end
end
