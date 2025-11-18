# frozen_string_literal: true

module RapidDiffs
  module Viewers
    module Text
      class ParallelViewComponent < ViewerComponent
        def self.viewer_name
          'text_parallel'
        end

        def virtual_rendering_params
          { total_rows: total_rows, rows_visibility: rows_visibility }
        end

        private

        def column_titles
          [
            s_('RapidDiffs|Original line number'),
            s_('RapidDiffs|Original line'),
            s_('RapidDiffs|Diff line number'),
            s_('RapidDiffs|Diff line')
          ]
        end

        def total_rows
          @diff_file.viewer_hunks.sum { |hunk| (hunk.header ? 1 : 0) + hunk.parallel_lines.count }
        end

        def rows_visibility
          total_rows >= Gitlab::Diff::File::ROWS_CONTENT_VISIBILITY_THRESHOLD ? 'auto' : nil
        end
      end
    end
  end
end
