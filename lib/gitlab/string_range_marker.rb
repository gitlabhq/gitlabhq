# frozen_string_literal: true

module Gitlab
  class StringRangeMarker
    include Gitlab::Utils::StrongMemoize

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
          if use_safe_position_mapping?
            mapped_length = position_mapping.length
            next if range.begin >= mapped_length

            effective_end = [range.end, mapped_length - 1].min
            effective_range = range.begin..effective_end
            rich_positions = position_mapping[effective_range].flatten
          else
            rich_positions = position_mapping[range].flatten
          end

          rich_marker_ranges.concat(collapse_ranges(rich_positions, range.mode))
        end
      else
        rich_marker_ranges = marker_ranges
      end

      offset = 0
      rich_marker_ranges.each_with_index do |range, i|
        offset_range = (range.begin + offset)..(range.end + offset)
        original_text = rich_line[offset_range]

        next if original_text.nil?

        text = yield(original_text, left: i == 0, right: i == rich_marker_ranges.length - 1, mode: range.mode)

        rich_line[offset_range] = text

        offset += text.length - original_text.length
      end

      @html_escaped ? rich_line.html_safe : rich_line
    end

    private

    def use_safe_position_mapping?
      Feature.enabled?(:fix_string_range_marker_infinite_loop, Feature.current_request)
    end
    strong_memoize_attr :use_safe_position_mapping?

    def position_mapping
      @position_mapping ||= if use_safe_position_mapping?
                              safe_position_mapping
                            else
                              legacy_position_mapping
                            end
    end

    def safe_position_mapping
      mapping = []
      rich_pos = 0

      (0..raw_line.length).each do |raw_pos|
        rich_pos = skip_html_tags(rich_pos)
        break if rich_pos.nil?

        rich_char = rich_char_at(rich_pos)
        break if rich_char.nil?

        if rich_char == '&'
          entity_positions = html_entity_positions(rich_pos)
          mapping[raw_pos] = entity_positions
          rich_pos = entity_positions.last + 1
        else
          mapping[raw_pos] = rich_pos
          rich_pos += 1
        end
      end

      mapping
    end

    def legacy_position_mapping
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

    def rich_char_at(pos)
      pos < rich_line.length ? rich_line[pos] : nil
    end

    def html_entity_positions(rich_pos)
      entity_end = rich_pos

      loop do
        char = rich_char_at(entity_end)
        break if char.nil? || char == ';'

        entity_end += 1
      end

      (rich_pos..entity_end).to_a
    end

    def skip_html_tags(rich_pos)
      while rich_char_at(rich_pos) == '<'
        rich_pos += 1 while rich_char_at(rich_pos)&.!= '>'
        return if rich_char_at(rich_pos).nil?

        rich_pos += 1
      end

      rich_pos
    end

    def collapse_ranges(positions, mode)
      return [] if positions.empty?

      ranges = []

      start = prev = positions[0]
      range = MarkerRange.new(start, prev, mode: mode)
      positions[1..].each do |pos|
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
