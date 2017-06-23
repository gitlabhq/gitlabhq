module Gitlab
  class StringRegexMarker < StringRangeMarker
    def mark(regex, group: 0, &block)
      regex_match = raw_line.match(regex)
      return rich_line unless regex_match

      begin_index, end_index = regex_match.offset(group)
      name_range = begin_index..(end_index - 1)

      super([name_range], &block)
    end
  end
end
