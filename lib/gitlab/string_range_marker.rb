# frozen_string_literal: true

module Gitlab
  class StringRangeMarker
    attr_accessor :raw_line, :rich_line, :html_escaped

    def initialize(raw_line, rich_line = nil)
      @raw_line = raw_line.dup
      if rich_line.nil?
        @rich_line = raw_line.dup
        @html_escaped = false
      else
        @rich_line = ERB::Util.html_escape(rich_line)
        @html_escaped = true
      end
    end

    def mark(ranges)
      return rich_line unless ranges&.any?

      marker_ranges = ranges.map { |range| Gitlab::MarkerRange.from_range(range) }

      if html_escaped
        rich_marker_ranges = []
        marker_ranges.each do |range|
          # Map the inline-diff range based on the raw line to character positions in the rich line
          rich_positions = position_mapping[range].flatten
          # Turn the array of character positions into ranges
          rich_marker_ranges.concat(collapse_ranges(rich_positions, range.mode))
        end
      else
        rich_marker_ranges = marker_ranges
      end

      offset = 0
      # Mark each range
      rich_marker_ranges.each_with_index do |range, i|
        offset_range = (range.begin + offset)..(range.end + offset)
        original_text = rich_line[offset_range]

        text = yield(original_text, left: i == 0, right: i == rich_marker_ranges.length - 1, mode: range.mode)

        rich_line[offset_range] = text

        offset += text.length - original_text.length
      end

      @html_escaped ? rich_line.html_safe : rich_line
    end

    private

    # Mapping of character positions in the raw line, to the rich (highlighted) line
    def position_mapping
      @position_mapping ||= begin
        mapping = []
        rich_pos = 0
        (0..raw_line.length).each do |raw_pos|
          rich_char = rich_line[rich_pos]

          # The raw and rich lines are the same except for HTML tags,
          # so skip over any `<...>` segment
          while rich_char == '<'
            until rich_char == '>'
              rich_pos += 1
              rich_char = rich_line[rich_pos]
            end

            rich_pos += 1
            rich_char = rich_line[rich_pos]
          end

          # multi-char HTML entities in the rich line correspond to a single character in the raw line
          if rich_char == '&'
            multichar_mapping = [rich_pos]
            until rich_char == ';'
              rich_pos += 1
              multichar_mapping << rich_pos
              rich_char = rich_line[rich_pos]
            end

            mapping[raw_pos] = multichar_mapping
          else
            mapping[raw_pos] = rich_pos
          end

          rich_pos += 1
        end

        mapping
      end
    end

    # Takes an array of integers, and returns an array of ranges covering the same integers
    def collapse_ranges(positions, mode)
      return [] if positions.empty?

      ranges = []

      start = prev = positions[0]
      range = MarkerRange.new(start, prev, mode: mode)
      positions[1..-1].each do |pos|
        if pos == prev + 1
          range = MarkerRange.new(start, pos, mode: mode)
          prev = pos
        else
          ranges << range
          start = prev = pos
          range = MarkerRange.new(start, prev, mode: mode)
        end
      end
      ranges << range

      ranges
    end
  end
end
