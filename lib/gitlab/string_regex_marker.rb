# frozen_string_literal: true

module Gitlab
  class StringRegexMarker < StringRangeMarker
    def mark(regex, group: 0, &block)
      ranges = []
      offset = 0

      while match = regex.match(raw_line[offset..])
        begin_index = match.begin(group) + offset
        end_index = match.end(group) + offset

        ranges << (begin_index..(end_index - 1))

        offset = end_index
      end

      super(ranges, &block)
    end
  end
end
