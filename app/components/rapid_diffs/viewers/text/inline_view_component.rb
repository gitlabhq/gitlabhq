# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineViewComponent < TextViewComponent
        def self.viewer_name
          'text_inline'
        end

        def lines
          @diff_file.diff_lines_with_match_tail
        end

        def diff_line(line)
          line
        end

        def hunk_view_component
          InlineHunkComponent
        end

        def column_titles
          [
            s_('RapidDiffs|Original line number'),
            s_('RapidDiffs|Diff line number'),
            s_('RapidDiffs|Diff line')
          ]
        end
      end
    end
  end
end
