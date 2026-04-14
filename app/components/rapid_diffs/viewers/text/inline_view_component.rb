# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class InlineViewComponent < TextViewComponent
        def self.viewer_name
          'text_inline'
        end

        private

        def column_titles
          [
            s_('RapidDiffs|Original line number'),
            s_('RapidDiffs|Diff line number'),
            s_('RapidDiffs|Diff line')
          ]
        end

        def total_rows
          @diff_file.viewer_hunks.sum { |hunk| (hunk.header ? 1 : 0) + hunk.lines.to_a.size }
        end
      end
    end
  end
end
