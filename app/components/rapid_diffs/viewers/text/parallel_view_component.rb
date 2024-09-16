# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class ParallelViewComponent < TextViewComponent
        def self.viewer_name
          'text_parallel'
        end

        def lines
          @diff_file.parallel_diff_lines_with_match_tail
        end

        # we need to iterate over diff lines to create an array of diff hunks
        # because parallel diffs can have empty sides we need to provide a line from a side that is not empty
        def diff_line(line)
          line[:left] || line[:right]
        end

        def hunk_view_component
          ParallelHunkComponent
        end

        def column_titles
          [
            s_('RapidDiffs|Original line number'),
            s_('RapidDiffs|Original line'),
            s_('RapidDiffs|Diff line number'),
            s_('RapidDiffs|Diff line')
          ]
        end
      end
    end
  end
end
