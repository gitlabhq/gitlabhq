# frozen_string_literal: true

module Gitlab
  class StringRegexMarker < StringRangeMarker
    # rubocop: disable CodeReuse/ActiveRecord
    def mark(regex, group: 0, &block)
      ranges = []

      raw_line.scan(regex) do
        begin_index, end_index = Regexp.last_match.offset(group)

        ranges << (begin_index..(end_index - 1))
      end

      super(ranges, &block)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
