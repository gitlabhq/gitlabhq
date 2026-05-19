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

        def hunks_with_row_counts
          @hunks_with_row_counts ||= @diff_file.viewer_hunks.index_with do |hunk|
            (hunk.header ? 1 : 0) + hunk.lines.to_a.size
          end
        end

        def total_rows
          @total_rows ||= hunks_with_row_counts.values.sum
        end
      end
    end
  end
end
